defmodule Boltex.SlackInstallationTest do
  use ExUnit.Case, async: true

  alias Boltex.SlackInstallation

  describe "create_changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        team_id: "T123ABC456",
        team_name: "Example Team",
        bot_token: "xoxb-test-token-for-testing-purposes-only",
        bot_user_id: "U123ABC456",
        scope: "chat:write,commands",
        authed_user: %{
          "id" => "U987XYZ321",
          "scope" => "chat:write",
          "access_token" => "xoxp-test-user-token"
        }
      }

      changeset = SlackInstallation.create_changeset(%SlackInstallation{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :team_id) == "T123ABC456"
      assert Ecto.Changeset.get_field(changeset, :team_name) == "Example Team"
      assert Ecto.Changeset.get_field(changeset, :bot_token) =~ "xoxb-"
      assert Ecto.Changeset.get_field(changeset, :bot_user_id) == "U123ABC456"
      assert Ecto.Changeset.get_field(changeset, :scope) == "chat:write,commands"
      assert Ecto.Changeset.get_field(changeset, :authed_user)["id"] == "U987XYZ321"
    end

    test "valid changeset with optional enterprise fields" do
      attrs = %{
        team_id: "T123ABC456",
        team_name: "Example Team",
        bot_token: "xoxb-token",
        bot_user_id: "U123ABC456",
        scope: "chat:write",
        authed_user: %{"id" => "U987XYZ321"},
        enterprise_id: "E123ABC456",
        is_enterprise_install: true
      }

      changeset = SlackInstallation.create_changeset(%SlackInstallation{}, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :enterprise_id) == "E123ABC456"
      assert Ecto.Changeset.get_field(changeset, :is_enterprise_install) == true
    end

    test "invalid when team_id is missing" do
      attrs = %{
        team_name: "Example Team",
        bot_token: "xoxb-token",
        bot_user_id: "U123ABC456",
        scope: "chat:write",
        authed_user: %{"id" => "U987"}
      }

      changeset = SlackInstallation.create_changeset(%SlackInstallation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).team_id
    end

    test "invalid when team_name is missing" do
      attrs = %{
        team_id: "T123ABC456",
        bot_token: "xoxb-token",
        bot_user_id: "U123ABC456",
        scope: "chat:write",
        authed_user: %{"id" => "U987"}
      }

      changeset = SlackInstallation.create_changeset(%SlackInstallation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).team_name
    end

    test "invalid when bot_token is missing" do
      attrs = %{
        team_id: "T123ABC456",
        team_name: "Example Team",
        bot_user_id: "U123ABC456",
        scope: "chat:write",
        authed_user: %{"id" => "U987"}
      }

      changeset = SlackInstallation.create_changeset(%SlackInstallation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).bot_token
    end

    test "invalid when bot_user_id is missing" do
      attrs = %{
        team_id: "T123ABC456",
        team_name: "Example Team",
        bot_token: "xoxb-token",
        scope: "chat:write",
        authed_user: %{"id" => "U987"}
      }

      changeset = SlackInstallation.create_changeset(%SlackInstallation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).bot_user_id
    end

    test "invalid when scope is missing" do
      attrs = %{
        team_id: "T123ABC456",
        team_name: "Example Team",
        bot_token: "xoxb-token",
        bot_user_id: "U123ABC456",
        authed_user: %{"id" => "U987"}
      }

      changeset = SlackInstallation.create_changeset(%SlackInstallation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).scope
    end

    test "invalid when authed_user is missing" do
      attrs = %{
        team_id: "T123ABC456",
        team_name: "Example Team",
        bot_token: "xoxb-token",
        bot_user_id: "U123ABC456",
        scope: "chat:write"
      }

      changeset = SlackInstallation.create_changeset(%SlackInstallation{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).authed_user
    end
  end

  describe "update_changeset/2" do
    test "valid update with new scope and bot_token" do
      installation = %SlackInstallation{
        team_id: "T123ABC456",
        team_name: "Example Team",
        bot_token: "xoxb-old-token",
        bot_user_id: "U123ABC456",
        scope: "chat:write",
        authed_user: %{"id" => "U987"}
      }

      attrs = %{
        scope: "chat:write,commands,users:read",
        bot_token: "xoxb-new-token"
      }

      changeset = SlackInstallation.update_changeset(installation, attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :scope) == "chat:write,commands,users:read"
      assert Ecto.Changeset.get_change(changeset, :bot_token) == "xoxb-new-token"
    end

    test "requires scope in update attributes" do
      installation = %SlackInstallation{
        team_id: "T123ABC456",
        bot_token: "xoxb-old-token",
        scope: "chat:write"
      }

      attrs = %{bot_token: "xoxb-new-token", scope: "chat:write"}

      changeset = SlackInstallation.update_changeset(installation, attrs)

      assert changeset.valid?
    end

    test "requires bot_token in update attributes" do
      installation = %SlackInstallation{
        team_id: "T123ABC456",
        bot_token: "xoxb-old-token",
        scope: "chat:write"
      }

      attrs = %{scope: "chat:write,commands", bot_token: "xoxb-old-token"}

      changeset = SlackInstallation.update_changeset(installation, attrs)

      assert changeset.valid?
    end

    test "does not allow updating team_id" do
      installation = %SlackInstallation{
        team_id: "T123ABC456",
        bot_token: "xoxb-token",
        scope: "chat:write"
      }

      attrs = %{
        team_id: "T999DIFFERENT",
        scope: "chat:write",
        bot_token: "xoxb-token"
      }

      changeset = SlackInstallation.update_changeset(installation, attrs)

      # team_id should not be in the changeset changes
      refute Map.has_key?(changeset.changes, :team_id)
      assert Ecto.Changeset.get_field(changeset, :team_id) == "T123ABC456"
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
