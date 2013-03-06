defmodule Genomu.Client.Sup do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])
  end

  def init(_) do
    supervise(tree, strategy: :one_for_one)
  end

  defmodule Connections do
    use Supervisor.Behaviour

    def start_link do
      :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])
    end

    def init(_) do
      supervise(tree, strategy: :simple_one_for_one)
    end

    defp tree do
      [worker(Genomu.Client.Connection, [])]
    end
  end

  defmodule Channels do
    use Supervisor.Behaviour

    def start_link do
      :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])
    end

    def init(_) do
      supervise(tree, strategy: :simple_one_for_one)
    end

    defp tree do
      [worker(Genomu.Client.Channel, [])]
    end
  end

  defp tree do
    [
      supervisor(Connections, []),
      supervisor(Channels, []),
    ]
  end

end

defmodule Genomu.Client.App do
  use Application.Behaviour

  def start(_, _) do
    Genomu.Client.Sup.start_link
  end

end