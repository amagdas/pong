defmodule Breakout.Game2D.Circle do
  alias Breakout.Game2D.Rect

  @enforce_keys [:x, :y, :radius]
  defstruct [:x, :y, :radius]

  def new(x: x, y: y, radius: radius), do: %__MODULE__{x: x, y: y, radius: radius}

  def to_rect(%__MODULE__{x: x, y: y, radius: radius}) do
    Rect.new(x: x - radius, y: y - radius, width: radius * 2 + 2, height: radius * 2 + 2)
  end
end
