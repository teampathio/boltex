defmodule Boltex.BlocksTest do
  use ExUnit.Case, async: true
  alias Boltex.Blocks

  describe "link/2" do
    test "formats a URL with display text in Slack's mrkdwn format" do
      result = Blocks.link("https://example.com", "Example Site")
      assert result == "<https://example.com|Example Site>"
    end
  end
end
