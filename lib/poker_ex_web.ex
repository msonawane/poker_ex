defmodule PokerExWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use PokerExWeb, :controller
      use PokerExWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: PokerExWeb

      alias PokerEx.Repo
      import Ecto
      import Ecto.Query

      import PokerExWeb.Support.ApiHelpers

      import PokerExWeb.Router.Helpers
      import PokerExWeb.Gettext
      import PokerExWeb.Auth, only: [authenticate_player: 2]
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/poker_ex_web/templates", namespace: PokerExWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PokerExWeb.Router.Helpers
      import PokerExWeb.ErrorHelpers
      import PokerExWeb.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import PokerExWeb.Auth, only: [authenticate_player: 2]
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias PokerEx.Repo
      import Ecto
      import Ecto.Query
      import PokerExWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
