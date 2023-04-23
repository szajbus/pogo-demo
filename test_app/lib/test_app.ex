defmodule TestApp do
  def start_pogo do
    Supervisor.start_child(
      TestApp.Supervisor,
      {Pogo.DynamicSupervisor,
       name: TestApp.DistributedSupervisor, scope: :test, sync_interval: 100}
    )
  end

  def start_child(child_spec) do
    Pogo.DynamicSupervisor.start_child(
      TestApp.DistributedSupervisor,
      child_spec
    )
  end
end
