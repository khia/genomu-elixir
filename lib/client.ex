defexception Genomu.Client.TimeoutException, message: "Timeout occured"
defexception Genomu.Client.AbortException, message: "Operation was aborted"

defmodule Genomu.Client do

  defmacro __using__(_) do
    quote do
      require Genomu.Client
    end
  end

  def connect(options) do
    :supervisor.start_child(Genomu.Client.Sup.Connections, [options])
  end

  def begin(conn, options // []) do
    Genomu.Client.Connection.start_channel(conn, options)
  end

  def watch(conn, fun, subscription) when is_binary(subscription) do
    watch(conn, fun, [subscription])
  end
  def watch(conn, fun, subscriptions) when is_list(subscriptions) do
    subscriptions = Enum.map(subscriptions, fn(s) when is_binary(s) -> [s]
                                              (s) -> s
                                            end)
    Genomu.Client.Connection.start_watcher(conn, fun, subscriptions)
  end

  def transaction(conn, f, options // []) when is_function(f, 1) do
    {:ok, ch} = begin(conn, options)
    try do
      result = f.(ch)
      :ok = commit(ch)
      result
    rescue e ->
      if Process.alive?(ch), do: discard(ch)
      raise e
    end
  end

  defmacro execute(conn, ch, [do: body]) do
    quote do
      Genomu.Client.transaction(unquote(conn), fn(unquote(ch)) -> unquote(body) end)
    end
  end
  defmacro execute(conn, ch, options) do
    body = options[:do]
    options = Keyword.delete(options, :do)
    quote do
      Genomu.Client.transaction(unquote(conn), fn(unquote(ch)) -> unquote(body) end, unquote(options))
    end
  end

  defdelegate [get(channel, addr, operation, options),
               get(channel, addr, operation_or_options),
               get(channel, addr),
               set(channel, addr, operation, options),
               set(channel, addr, operation),
               apply(channel, addr, operation, options),
               apply(channel, addr, operation),
               operation(channel, addr),
               operation(channel, addr, options),
               commit(channel), discard(channel)], to: Genomu.Client.Channel
end