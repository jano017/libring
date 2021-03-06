defmodule HashRing.App do
  @moduledoc false
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec

    # Start the ring supervisor
    children = [
      worker(HashRing.Worker, [], restart: :transient)
    ]
    pid = case Supervisor.start_link(children, strategy: :simple_one_for_one, name: HashRing.Supervisor) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end

    # Add any preconfigured rings
    Enum.each(Application.get_env(:libring, :rings, []), fn
      {name, config} ->
        {:ok, _pid} = HashRing.Managed.get(name, config)
        Logger.info "[libring] started managed ring #{inspect name}"
      name when is_atom(name) ->
        {:ok, _pid} = HashRing.Managed.get(name)
        Logger.info "[libring] started managed ring #{inspect name}"
    end)

    # Application started
    {:ok, pid}
  end
end
