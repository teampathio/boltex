defmodule Boltex.Installations.RepoConfigTest do
  use ExUnit.Case, async: false

  alias Boltex.Installations

  describe "repo configuration" do
    test "raises error when repo is not configured" do
      # Temporarily remove repo config
      original_repo = Application.get_env(:boltex, :repo)
      Application.delete_env(:boltex, :repo)

      assert_raise RuntimeError, ~r/Boltex requires :repo to be configured/, fn ->
        Installations.find("T123")
      end

      # Restore repo config
      Application.put_env(:boltex, :repo, original_repo)
    end
  end
end
