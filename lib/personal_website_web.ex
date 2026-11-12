defmodule PersonalWebsiteWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PersonalWebsiteWeb, :controller
      use PersonalWebsiteWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [html: "View", xml: "View"],
        layouts: [html: {PersonalWebsiteWeb.LayoutView, :app}]

      import Plug.Conn
      import Phoenix.LiveView.Controller
      alias PersonalWebsiteWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/personal_website_web/templates",
        namespace: PersonalWebsiteWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [view_module: 1, view_template: 1, get_csrf_token: 0]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PersonalWebsiteWeb.LayoutView, :live}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      import Phoenix.HTML
      use PhoenixHTMLHelpers

      import Phoenix.Component
      import Phoenix.View
      import PersonalWebsiteWeb.ErrorHelpers

      alias PersonalWebsiteWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
