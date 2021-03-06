defmodule PokerExWeb.GameView do
  use PokerExWeb, :view
  import Ecto.Query

  @errors [:out_of_turn, :not_paid, :already_joined]

  ### TODO: Extract all errors that can be output by the
  ### GameEngine.Impl functions and create user-facing messages
  ### for each of them. This first render function is temporary
  ### and should be updated to show better error messages.
  def render("game.json", %{game: game}) when game in @errors, do: %{message: game}

  def render("game.json", %{game: game}) do
    active = if game.player_tracker.active == [], do: nil, else: hd(game.player_tracker.active)

    players =
      case game.player_tracker.active do
        [] ->
          []

        active ->
          Enum.map(active, fn name ->
            PokerEx.Repo.one(from(p in PokerEx.Player, where: p.name == ^name))
          end)
      end

    %{
      active: active,
      current_big_blind: view_blind(game.roles.big_blind),
      current_small_blind: view_blind(game.roles.small_blind),
      state: Atom.to_string(game.phase),
      paid: game.chips.paid,
      to_call: game.chips.to_call,
      players: Phoenix.View.render_many(players, PokerExWeb.PlayerView, "player.json"),
      chip_roll: game.chips.chip_roll,
      type: Atom.to_string(game.type),
      seating:
        Phoenix.View.render_many(
          game.seating.arrangement,
          __MODULE__,
          "seating.json",
          as: :seating
        ),
      player_hands:
        Phoenix.View.render_many(
          game.cards.player_hands,
          __MODULE__,
          "player_hands.json",
          as: :player_hand
        ),
      round: game.chips.round,
      pot: game.chips.pot,
      table:
        if(
          game.cards.table == [],
          do: [],
          else: Phoenix.View.render_many(game.cards.table, __MODULE__, "card.json", as: :card)
        ),
      leaving: game.async_manager.cleanup_queue
    }
  end

  def render("player_hands.json", %{player_hand: %{hand: []}}), do: %{}

  def render("player_hands.json", %{player_hand: %{player: player, hand: hand}}) do
    %{player: player, hand: Enum.map(hand, &Map.from_struct/1)}
  end

  def render("seating.json", %{seating: {name, position}}) do
    %{name: name, position: position}
  end

  def render("card.json", %{card: card}) do
    %{rank: card.rank, suit: card.suit}
  end

  def view_blind(:unset), do: 0
  def view_blind(blind), do: blind
end
