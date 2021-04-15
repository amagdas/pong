defmodule Breakout.Game2D.Rect do
  @enforce_keys [:x, :y, :width, :height]
  defstruct [:x, :y, :width, :height]

  def new(x: x, y: y, width: width, height: height) do
    %__MODULE__{x: x, y: y, width: width, height: height}
  end

  def intersects?(%__MODULE__{} = rect1, %__MODULE__{} = rect2) do
    rect1.x < rect2.x + rect2.width and
      rect1.y < rect2.y + rect2.height and
      rect1.x + rect1.width > rect2.x and
      rect1.y + rect1.height > rect2.y
  end

  def left(%__MODULE__{x: x}), do: x
  def right(%__MODULE__{x: x, width: width}), do: x + width - 1
  def top(%__MODULE__{y: y}), do: y
  def bottom(%__MODULE__{y: y, height: height}), do: y + height - 1

  def intersection(rect1, rect2) do
    l = max(left(rect1), left(rect2))
    r = min(right(rect1), right(rect2))
    t = max(top(rect1), top(rect2))
    b = min(bottom(rect1), bottom(rect2))

    cond do
      l > r or t > b ->
        nil

      true ->
        width = r - l + 1
        height = b - t + 1
        new(x: l, y: t, width: width, height: height)
    end
  end
end
