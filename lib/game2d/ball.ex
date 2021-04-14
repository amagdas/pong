defmodule Breakout.Game2D.Ball do
  alias Breakout.Game2D.Circle

  @enforce_keys [:circle, :vx, :vy]
  defstruct [:circle, :vx, :vy]

  def new(x: x, y: y, radius: radius, vx: vx, vy: vy) do
    %__MODULE__{circle: Circle.new(x, y, radius), vx: vx, vy: vy}
  end

  def to_rect(%__MODULE__{} = ball) do
    Circle.to_rect(ball.circle)
  end
end
