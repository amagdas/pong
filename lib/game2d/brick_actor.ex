defmodule Breakout.Game2D.BrickActor do
  use GenServer
  alias Breakout.Game2D.Brick
  alias Breakout.Game2D.Rect

  # Client
  def start_link(brick) do
    GenServer.start_link(__MODULE__, brick)
  end

  def new(id: id, x: x, y: y, width: width, height: height, color: color) do
    {:ok, brick} =
      DynamicSupervisor.start_child(
        Breakout.DynamicSupervisor,
        {__MODULE__, Brick.new(id: id, x: x, y: y, width: width, height: height, color: color)}
      )

    brick
    |> IO.inspect(label: "PID for #{id}:")
  end

  def rect_spec(pid) do
    GenServer.call(pid, :rect_spec)
  end

  def collides?(pid, rect) do
    case Process.alive?(pid) do
      true ->
        GenServer.call(pid, {:collides, rect})

      false ->
        nil
    end
  end

  def alive?(pid) do
    Process.alive?(pid) and GenServer.call(pid, :alive)
  end

  def active?(pid) do
    case alive?(pid) do
      {id, false} ->
        terminate_child(pid, id)
        false

      {_id, true} ->
        true

      _ ->
        false
    end
  end

  # Server callbacks
  @impl true
  def init(brick) do
    {:ok, brick}
  end

  @impl true
  def handle_call(:rect_spec, _from, brick) do
    dims = Brick.dimensions(brick)

    options = [
      fill: Brick.color(brick),
      translate: Brick.position(brick),
      id: Brick.id(brick)
    ]

    {:reply, {dims, options}, brick}
  end

  @impl true
  def handle_call({:collides, rect}, _from, brick) do
    collision = Rect.intersection(rect, Brick.rect(brick))

    case collision do
      nil ->
        {:reply, collision, brick}

      collision ->
        {:reply, collision, Brick.kill(brick)}
    end
  end

  @impl true
  def handle_call(:alive, _from, brick) do
    {:reply, {Brick.id(brick), Brick.alive?(brick)}, brick}
  end

  defp terminate_child(pid, id) do
    :ok = DynamicSupervisor.terminate_child(Breakout.DynamicSupervisor, pid)

    DynamicSupervisor.count_children(Breakout.DynamicSupervisor)
    |> IO.inspect(label: "killed brick: #{id}")
  end
end
