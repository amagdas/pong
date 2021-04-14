defmodule Breakout.Game2D.Rect do
  @enforce_keys [:x, :y, :width, :height]
  defstruct [:x, :y, :width, :height]

  def new(x: x, y: y, width: width, height: height) do
    %__MODULE__{x: x, y: y, width: width, height: height}
  end
end
