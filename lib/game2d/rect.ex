defmodule Breakout.Game2D.Rect do
  @enforce_keys [:x, :y, :width, :height]
  defstruct [:x, :y, :width, :height]

  def new(x: x, y: y, width: width, height: height) do
    %__MODULE__{x: x, y: y, width: width, height: height}
  end

  def intersects?(%__MODULE__{} = rect1, %__MODULE__{} = rect2) do
    case intersection(rect1, rect2) do
      nil -> false
      _ -> true
    end
  end

  def left(%__MODULE__{x: x}), do: x
  def right(%__MODULE__{x: x, width: width}), do: x + width - 1
  def top(%__MODULE__{y: y}), do: y
  def bottom(%__MODULE__{y: y, height: height}), do: y + height - 1

  def intersection(%__MODULE__{} = rect1, %__MODULE__{} = rect2) do
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
