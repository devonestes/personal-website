defmodule PersonalWebsite.DiabetesTest do
  use ExUnit.Case, async: true

  alias PersonalWebsite.Diabetes

  describe "get_data/0" do
    test "does the thing" do
      Diabetes.update_data(1)
    end
  end
end
