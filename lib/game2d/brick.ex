defmodule Breakout.Game2D.Brick do
  alias Breakout.Game2D.Rect

  @enforce_keys [:id, :rect, :dead, :color]
  defstruct [:id, :rect, :dead, :color]

  def new(id: id, x: x, y: y, width: width, height: height, color: color) do
    %__MODULE__{
      id: id,
      rect: Rect.new(x: x, y: y, width: width, height: height),
      dead: false,
      color: color
    }
  end

  def position(%__MODULE__{} = brick) do
    {brick.rect.x, brick.rect.y}
  end

  def dimensions(%__MODULE__{} = brick) do
    {brick.rect.width, brick.rect.height}
  end

  def id(%__MODULE__{} = brick), do: brick.id
  def rect(%__MODULE__{} = brick), do: brick.rect
  def color(%__MODULE__{} = brick), do: brick.color
  def dead?(%__MODULE__{} = brick), do: brick.dead
  def kill(%__MODULE__{} = brick), do: %{brick | dead: true}
  def alive?(%__MODULE__{} = brick), do: brick.dead == false
end
