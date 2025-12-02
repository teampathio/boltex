defmodule Boltex.Blocks do
  @moduledoc """
  Helpers for building Slack Block Kit composition objects and elements.

  This module provides functions for creating Block Kit composition objects
  that are used throughout Slack's Block Kit framework.

  See: https://api.slack.com/reference/block-kit/composition-objects

  ## Examples

      import Boltex.Blocks

      # Build a simple text block
      %{
        type: "section",
        text: mrkdwn("*Bold* and _italic_ text")
      }

      # Build a header with plain text
      %{
        type: "header",
        text: plain_text("Welcome! :wave:")
      }
  """

  @doc """
  Builds a plain_text composition object.

  Plain text is used in most places where text can appear in Block Kit.
  It will be rendered without any formatting or markup.

  See: https://docs.slack.dev/reference/block-kit/composition-objects/text-object/

  ## Options

    * `:emoji` - When `true`, emoji codes like `:smile:` will be rendered
      as emoji. Defaults to not being set.

  ## Examples

      iex> plain_text("Hello World")
      %{type: "plain_text", text: "Hello World"}

      iex> plain_text("Hello :wave:", emoji: true)
      %{type: "plain_text", text: "Hello :wave:", emoji: true}
  """
  @spec plain_text(String.t(), emoji: boolean()) :: map()
  def plain_text(text, opts \\ []) do
    %{type: "plain_text", text: text}
    |> put_opts(opts, [:emoji])
  end

  @doc """
  Builds a mrkdwn (markdown) composition object.

  Mrkdwn allows you to use Slack's markdown-like formatting.
  Supports bold, italic, strikethrough, code, and links.

  See: https://docs.slack.dev/reference/block-kit/composition-objects/text-object/

  ## Options

    * `:verbatim` - When `true`, disables automatic URL parsing and
      @mentions/@channel formatting. Defaults to not being set.

  ## Examples

      iex> mrkdwn("*Bold* and _italic_ text")
      %{type: "mrkdwn", text: "*Bold* and _italic_ text"}

      iex> mrkdwn("Plain text", verbatim: true)
      %{type: "mrkdwn", text: "Plain text", verbatim: true}

      iex> mrkdwn("<https://example.com|Link text>")
      %{type: "mrkdwn", text: "<https://example.com|Link text>"}
  """
  @spec mrkdwn(String.t(), verbatim: boolean()) :: map()
  def mrkdwn(text, opts \\ []) do
    %{type: "mrkdwn", text: text}
    |> put_opts(opts, [:verbatim])
  end

  @doc """
  Builds a button element.

  Buttons are interactive elements that can be clicked by users to trigger actions.

  See: https://docs.slack.dev/reference/block-kit/block-elements/button-element/

  ## Options

    * `:value` - A string that will be sent to your app when the button is clicked.
      Maximum length of 2000 characters.
    * `:url` - A URL to load in the user's browser when the button is clicked.
      Maximum length of 3000 characters.
    * `:style` - Visual style of the button. Can be `:primary` (green) or `:danger` (red).
    * `:confirm` - A confirmation dialog object that will be shown before the action is sent.
    * `:accessibility_label` - A label for accessibility purposes (screen readers).

  ## Examples

      iex> button("Click me", "button_click")
      %{type: "button", text: %{type: "plain_text", text: "Click me"}, action_id: "button_click"}

      iex> button("Save", "save_action", style: :primary, value: "save_data")
      %{
        type: "button",
        text: %{type: "plain_text", text: "Save"},
        action_id: "save_action",
        style: "primary",
        value: "save_data"
      }

      iex> button("Open Link", "link_button", url: "https://example.com")
      %{
        type: "button",
        text: %{type: "plain_text", text: "Open Link"},
        action_id: "link_button",
        url: "https://example.com"
      }
  """
  @spec button(String.t(), String.t(),
          value: String.t(),
          url: String.t(),
          style: :primary | :danger,
          confirm: map(),
          accessibility_label: String.t()
        ) :: map()
  def button(text, action_id, opts \\ []) do
    %{
      type: "button",
      text: plain_text(text),
      action_id: action_id
    }
    |> put_opts(opts, [:value, :url, :style, :confirm, :accessibility_label])
  end

  @doc """
  Formats a URL with display text in Slack's mrkdwn link format.

  Returns a string formatted as `<href|text>` which Slack will render
  as a clickable link with the specified display text.

  See: https://api.slack.com/reference/surfaces/formatting#linking-urls

  ## Examples

      iex> link("https://example.com", "Example Site")
      "<https://example.com|Example Site>"

      iex> link("https://slack.com/help", "Help Center")
      "<https://slack.com/help|Help Center>"
  """
  @spec link(String.t(), String.t()) :: String.t()
  def link(href, text) do
    "<#{href}|#{text}>"
  end

  @doc """
  Formats a user mention in Slack's mrkdwn format.

  Returns a string formatted as `<@user_id>` which Slack will render
  as a clickable mention of the user.

  See: https://api.slack.com/reference/surfaces/formatting#mentioning-users

  ## Examples

      iex> mention("U123456")
      "<@U123456>"
  """
  @spec mention(String.t()) :: String.t()
  def mention(user_id) do
    "<@#{user_id}>"
  end

  @doc """
  Creates a divider block.

  A divider is a simple visual separator that can be used to divide content.

  See: https://api.slack.com/reference/block-kit/blocks#divider

  ## Examples

      iex> divider()
      %{type: "divider"}
  """
  @spec divider() :: map()
  def divider do
    %{type: "divider"}
  end

  defp put_opts(map, opts, keys) do
    Enum.reduce(keys, map, fn key, acc ->
      case Keyword.get(opts, key) do
        nil -> acc
        value -> Map.put(acc, key, value)
      end
    end)
  end
end
