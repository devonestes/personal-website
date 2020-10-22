defmodule PersonalWebsite.RetirementTest do
  use ExUnit.Case, async: true

  alias PersonalWebsite.Retirement

  describe "can_i_retire_yet?/1" do
    test "returns true if I have a ton of money" do
      {:ok, today} = Date.new(2070, 11, 13)
      assert Retirement.can_i_retire_yet?(10_000_000, today)
    end

    test "returns false if I have very little money" do
      {:ok, today} = Date.new(2070, 11, 13)
      refute Retirement.can_i_retire_yet?(10, today)
    end
  end

  describe "needed_to_retire/1" do
    test "returns the right value for a date far in the future" do
      {:ok, today} = Date.new(2070, 11, 13)
      assert Retirement.needed_to_retire(today) == 228_120
    end

    test "returns the right value for a date in 2020" do
      {:ok, today} = Date.new(2020, 11, 13)
      assert Retirement.needed_to_retire(today) == 1_448_954
    end
  end
end
