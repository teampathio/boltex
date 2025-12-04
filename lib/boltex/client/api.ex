defmodule Boltex.Client.Api do
  @moduledoc """
  Real implementation of Slack API client.
  Makes actual HTTP requests to Slack API via Tesla.
  """

  @behaviour Boltex.ClientBehaviour

  require Logger

  alias Boltex.Client.ApiError

  @impl true
  def chat_post_message(client, channel, arguments \\ %{}) do
    arguments = Map.put(arguments, :channel, channel)
    post(client, "chat.postMessage", arguments)
  end

  @impl true
  def chat_update(client, channel, ts, arguments \\ %{}) do
    arguments =
      arguments
      |> Map.put(:channel, channel)
      |> Map.put(:ts, ts)

    post(client, "chat.update", arguments)
  end

  @impl true
  def chat_get_permalink(client, channel, message_ts) do
    get(client, "chat.getPermalink", %{channel: channel, message_ts: message_ts})
  end

  @impl true
  def views_publish(client, user_id, view, arguments \\ %{}) do
    arguments =
      arguments
      |> Map.put(:user_id, user_id)
      |> Map.put(:view, view)

    post(client, "views.publish", arguments)
  end

  @impl true
  def views_open(client, trigger_id, view, arguments \\ %{}) do
    arguments =
      arguments
      |> Map.put(:trigger_id, trigger_id)
      |> Map.put(:view, view)

    post(client, "views.open", arguments)
  end

  @impl true
  def users_info(client, user_id, arguments \\ %{}) do
    arguments = Map.put(arguments, :user, user_id)
    get(client, "users.info", arguments)
  end

  @impl true
  def users_lookup_by_email(client, email) do
    get(client, "users.lookupByEmail", %{email: email})
  end

  @impl true
  def conversations_join(client, channel, arguments \\ %{}) do
    arguments = Map.put(arguments, :channel, channel)
    post(client, "conversations.join", arguments)
  end

  @impl true
  def conversations_list(client, arguments \\ %{}) do
    get(client, "conversations.list", arguments)
  end

  @impl true
  def users_list(client, arguments \\ %{}) do
    get(client, "users.list", arguments)
  end

  defp post(client, operation, params) do
    url = "#{client.base_url}/#{operation}"
    request(:post, client, url, params)
  end

  defp get(client, operation, params) do
    url = "#{client.base_url}/#{operation}"
    query = URI.encode_query(params)
    request(:get, client, "#{url}?#{query}")
  end

  defp request(http_method, client, url, body \\ nil) do
    middleware = [
      {Tesla.Middleware.BearerAuth, token: client.token},
      {Tesla.Middleware.JSON, encode_content_type: "application/json; charset=utf-8"},
      Tesla.Middleware.KeepRequest
    ]

    http_client = Tesla.client(middleware)

    opts = [method: http_method, url: url]
    opts = if body, do: Keyword.put(opts, :body, body), else: opts
    result = Tesla.request(http_client, opts)

    case result do
      {:ok, %{status: 200, body: %{"ok" => true} = response}} ->
        {:ok, response}

      {:ok, %{status: 200, body: %{"ok" => false}} = request} ->
        error = ApiError.from_request(request)
        Logger.error(to_string(error))
        {:error, error}

      {:ok, response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
