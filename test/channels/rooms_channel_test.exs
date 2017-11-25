defmodule PokerEx.RoomChannelTest do
	use PokerExWeb.ChannelCase
	import PokerEx.TestHelpers
	alias PokerExWeb.RoomsChannel
	alias PokerEx.Room

	@endpoint PokerExWeb.Endpoint
	@default_chips 500

	setup do
		{:ok, _} = Room.start_link("room_test")
		
		{socket, player, token, reply} = create_player_and_connect()
		@endpoint.subscribe("rooms:room_test")
		
		{:ok, socket: socket, player: player, token: token, reply: reply}
	end

	test "authentication works", context do
		assert {:player_id, context.player.id} in context.socket.assigns
	end

	test "room join", context do
		for key <- [:join_amount, :player, :type, :room] do
			assert key in Map.keys(context.socket.assigns)
		end

		seated_players = for {player, _pos} <- Room.state(:room_test).seating, do: player
		
		assert context.player.name in seated_players
		assert Room.which_state(:room_test) == :idle
	end
	
	test "a game starts when a second player joins", context do
		{_, player, _, _} = create_player_and_connect()

		room_state = Room.state(:room_test)
		seated_players = for {player, _} <- room_state.seating, do: player
		
		for player <- [context.player.name, player.name], do: assert player in seated_players
		
		assert_broadcast "game_started", 
			%{active: _, chip_roll: %{}, paid: %{},
				player_hands: [%{hand: [%{rank: _, suit: _}, %{rank: _, suit: _}], player: _},
											 %{hand: [%{rank: _, suit: _}, %{rank: _, suit: _}], player: _}
											],
				players: [%{chips: _, name: _}, %{chips: _, name: _}],
				pot: 15,
				round: %{},
				seating: [%{name: _, position: _}, %{name: _, position: _}],
				table: [],
				to_call: 10,
				type: "public"
			 }
		assert Room.which_state(:room_test) == :pre_flop
	end
	
	test "channel broadcasts actions taken by players", context do
		{_, player, _, _} = create_player_and_connect()
		player_name = player.name
		
		{active_player, _} = Room.state(:room_test).active |> hd()
		assert active_player == context.player.name
		
		push context.socket, "action_raise", %{"player" => context.player.name, "amount" => 25}
		
		assert_broadcast "update", %{active: ^player_name, pot: 35}
			 
		push context.socket, "action_call", %{"player" => player.name}
		
		assert_broadcast "update", %{active: ^active_player, pot: 50}
			 
		push context.socket, "action_check", %{"player" => context.player.name}
		
		assert_broadcast "update", %{active: ^player_name, pot: 50}
		
		push context.socket, "action_check", %{"player" => player.name}
		
		push context.socket, "action_raise", %{"player" => context.player.name, "amount" => 50}
		
		assert_broadcast "update", %{active: ^player_name, pot: 100}
		
		push context.socket, "action_fold", %{"player" => player.name}
		
		assert_broadcast "update", %{state: :turn}
		
		assert_broadcast "winner_message", %{message: _}
		
		assert_broadcast "game_finished", %{message: _}
	end
	
	test "a new update message is broadcast when a player manually sends a leave message", context do
		{_, player, _, _} = create_player_and_connect()
		
		seating = Room.state(:room_test).seating
		assert length(seating) == 2
		assert Room.which_state(:room_test) == :pre_flop
		
		expected_player_remaining = context.player.name

		push context.socket, "action_leave", %{"player" => player.name}
		
		assert_broadcast "update", %{seating: [%{name: ^expected_player_remaining, position: 0}]}
		
		Process.sleep(100)
		seating_after_leave = Room.state(:room_test).seating
		assert length(seating_after_leave) == 1
	end
	
	test "a new update message is broadcast when a player's channel is disconnected", context do
		{_, player, _, _} = create_player_and_connect()
		
		# Since a :skip_update_message is returned if there are only two players
		# and one leaves/gets disconnected (leaving only one player at the table), I'm having a
		# third player join here to invoke what would normally be returned given an ongoing game with
		# more than two players.

		{_, other_player, _, _} = create_player_and_connect()
		
		assert length(Room.state(:room_test).seating) == 3
		assert Room.which_state(:room_test) == :pre_flop
		
		expected_seating = [%{name: player.name, position: 0}, %{name: other_player.name, position: 1}]
		
		leave(context.socket)
		
		assert_broadcast "update", %{seating: ^expected_seating}
		
		Process.sleep(100)
		assert length(Room.state(:room_test).seating) == 2
	end
	
	test "when there are only two players and one leaves, the channel broadcasts a 'clear_ui' message", _context do
		{socket, _, _, _} = create_player_and_connect()
		
		assert length(Room.state(:room_test).seating) == 2
		
		leave(socket)
		
		Process.sleep(100)
		assert_broadcast "clear_ui", %{}
	end

	test "the channel issues a push with the number of available chips when receiving a 'get_bank' message", context do
		push context.socket, "get_bank", %{"player" => context.player.name}

		chips = PokerEx.Player.chips(context.player.name)

		assert_push "bank_info", ^chips
	end

	test "the channel broadcasts an update when a player submits an add_chips action", context do
		create_player_and_connect()

		player_name = context.player.name		
		push context.socket, "action_add_chips", %{"player" => player_name, "amount" => 200}

		Process.sleep(100)
		chips = Room.state(:room_test).chip_roll[player_name]

		assert_broadcast "update", %{chip_roll: %{^player_name => ^chips}}
	end
	
	defp create_player_and_connect do
		player = insert_user()
		
		token = Phoenix.Token.sign(socket(), "user socket", player.id)
		
		{:ok, socket} = connect(PokerExWeb.UserSocket, %{"token" => token})
		
		{:ok, reply, socket} = subscribe_and_join(socket, RoomsChannel, "rooms:room_test",
																							%{"type" => "public", "amount" => @default_chips})
																							
		{socket, player, token, reply}								
	end
end