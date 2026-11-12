defmodule PersonalWebsiteWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  import PhoenixHTMLHelpers.Tag, only: [content_tag: 3]
  import Phoenix.HTML.Form, only: [input_id: 2]

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, error,
        class: "help-block",
        data: [phx_error_for: input_id(form, field)]
      )
    end)
  end
end
