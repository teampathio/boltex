defmodule Boltex.ClientBehaviour do
  @moduledoc """
  Behaviour for Slack API client operations.
  Adapters must implement these callbacks matching the public API.
  """

  alias Boltex.Client.ApiError

  @type slack_response :: map()
  @type error_reason :: ApiError.t() | Tesla.Env.t()

  @callback chat_post_message(
              client :: Boltex.Client.t(),
              channel :: String.t(),
              arguments :: map()
            ) ::
              {:ok, slack_response()} | {:error, error_reason()}

  @callback chat_update(
              client :: Boltex.Client.t(),
              channel :: String.t(),
              ts :: String.t(),
              arguments :: map()
            ) ::
              {:ok, slack_response()} | {:error, error_reason()}

  @callback views_publish(
              client :: Boltex.Client.t(),
              user_id :: String.t(),
              view :: map(),
              arguments :: map()
            ) ::
              {:ok, slack_response()} | {:error, error_reason()}

  @callback users_info(
              client :: Boltex.Client.t(),
              user_id :: String.t(),
              arguments :: map()
            ) ::
              {:ok, slack_response()} | {:error, error_reason()}

  @callback conversations_join(
              client :: Boltex.Client.t(),
              channel :: String.t(),
              arguments :: map()
            ) ::
              {:ok, slack_response()} | {:error, error_reason()}

  @callback conversations_list(client :: Boltex.Client.t(), arguments :: map()) ::
              {:ok, slack_response()} | {:error, error_reason()}

  @callback users_lookup_by_email(client :: Boltex.Client.t(), email :: String.t()) ::
              {:ok, slack_response()} | {:error, error_reason()}

  @callback views_open(
              client :: Boltex.Client.t(),
              trigger_id :: String.t(),
              view :: map(),
              arguments :: map()
            ) ::
              {:ok, slack_response()} | {:error, error_reason()}

  @callback users_list(client :: Boltex.Client.t(), arguments :: map()) ::
              {:ok, slack_response()} | {:error, error_reason()}
end
