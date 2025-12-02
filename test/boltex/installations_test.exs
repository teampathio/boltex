defmodule Boltex.InstallationsTest do
  use ExUnit.Case, async: true
  import Mox

  alias Boltex.Installations
  alias Boltex.SlackInstallation

  setup :verify_on_exit!

  describe "save/1" do
    test "creates a new installation when team_id doesn't exist" do
      installation_params = %{
        team_id: "T123",
        team_name: "Test Team",
        bot_token: "xoxb-test",
        bot_user_id: "U123",
        scope: "chat:write",
        authed_user: %{"id" => "U456"}
      }

      expect(Boltex.MockRepo, :get_by, fn SlackInstallation, team_id: "T123" ->
        nil
      end)

      expect(Boltex.MockRepo, :insert, fn changeset ->
        installation = Ecto.Changeset.apply_changes(changeset)
        {:ok, installation}
      end)

      assert {:ok, installation} = Installations.save(installation_params)
      assert installation.team_id == "T123"
      assert installation.team_name == "Test Team"
    end

    test "updates existing installation when team_id exists" do
      existing = %SlackInstallation{
        team_id: "T123",
        team_name: "Old Name",
        bot_token: "xoxb-old",
        bot_user_id: "U123",
        scope: "old_scope",
        authed_user: %{}
      }

      installation_params = %{
        team_id: "T123",
        team_name: "Old Name",
        bot_token: "xoxb-new",
        bot_user_id: "U123",
        scope: "new_scope",
        authed_user: %{}
      }

      expect(Boltex.MockRepo, :get_by, fn SlackInstallation, team_id: "T123" ->
        existing
      end)

      expect(Boltex.MockRepo, :update, fn changeset ->
        installation = Ecto.Changeset.apply_changes(changeset)
        {:ok, installation}
      end)

      assert {:ok, installation} = Installations.save(installation_params)
      assert installation.bot_token == "xoxb-new"
      assert installation.scope == "new_scope"
    end
  end

  describe "find/1" do
    test "returns installation when found" do
      installation = %SlackInstallation{team_id: "T123", team_name: "Test"}

      expect(Boltex.MockRepo, :get_by, fn SlackInstallation, team_id: "T123" ->
        installation
      end)

      assert {:ok, ^installation} = Installations.find("T123")
    end

    test "returns error when not found" do
      expect(Boltex.MockRepo, :get_by, fn SlackInstallation, team_id: "T999" ->
        nil
      end)

      assert {:error, :not_found} = Installations.find("T999")
    end
  end

  describe "find_bot_token/1" do
    test "returns bot token when found" do
      expect(Boltex.MockRepo, :one, fn _query ->
        "xoxb-token"
      end)

      assert {:ok, "xoxb-token"} = Installations.find_bot_token("T123")
    end

    test "returns error when not found" do
      expect(Boltex.MockRepo, :one, fn _query ->
        nil
      end)

      assert {:error, :not_found} = Installations.find_bot_token("T999")
    end
  end

  describe "delete/1" do
    test "deletes installation" do
      expect(Boltex.MockRepo, :delete_all, fn _query ->
        {1, nil}
      end)

      assert :ok = Installations.delete("T123")
    end
  end

  describe "list/0" do
    test "returns all installations" do
      installations = [
        %SlackInstallation{team_id: "T1"},
        %SlackInstallation{team_id: "T2"}
      ]

      expect(Boltex.MockRepo, :all, fn SlackInstallation ->
        installations
      end)

      assert {:ok, ^installations} = Installations.list()
    end
  end
end
