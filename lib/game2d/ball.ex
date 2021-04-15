defmodule Breakout.Game2D.Ball do
  alias Breakout.Game2D.Circle
  alias Breakout.Game2D.Rect

  @enforce_keys [:circle, :vx, :vy]
  defstruct [:circle, :vx, :vy]

  def new(x: x, y: y, radius: radius, vx: vx, vy: vy) do
    %__MODULE__{circle: Circle.new(x: x, y: y, radius: radius), vx: vx, vy: vy}
  end

  def radius(%__MODULE__{} = ball), do: ball.circle.radius

  def translate(%__MODULE__{} = ball) do
    {ball.circle.x, ball.circle.y}
  end

  def to_rect(%__MODULE__{} = ball) do
    Circle.to_rect(ball.circle)
  end

  def deflect(%__MODULE__{} = ball, %Rect{width: width, height: height}) do
    if width < height do
      %__MODULE__{ball | vx: ball.vx * -1}
    else
      %__MODULE__{ball | vy: ball.vy * -1}
    end
  end

  def paddle_hit?(%__MODULE__{} = ball, %Rect{} = paddle_rect, %__MODULE__{} = prev_ball) do
    case to_rect(ball)
         |> Rect.intersects?(paddle_rect) do
      true ->
        prev_pos = %{ball.circle | y: prev_ball.circle.y}
        %{ball | circle: prev_pos, vy: ball.vy * -1}

      _ ->
        ball
    end
  end

  def compute_next_position(%__MODULE__{} = ball, viewport_width) do
    next_pos = %{ball.circle | x: ball.circle.x + ball.vx, y: ball.circle.y + ball.vy}

    %{ball | circle: next_pos}
    |> out_of_bounds_x?(ball, viewport_width)
    |> out_of_bounds_y?(ball)
  end

  defp out_of_bounds_x?(
         %__MODULE__{circle: %Circle{x: x, radius: radius}} = ball,
         %__MODULE__{} = prev_ball,
         viewport_width
       )
       when x < radius or x > viewport_width - radius do
    next_pos = %{ball.circle | x: prev_ball.circle.x}
    %{ball | circle: next_pos, vx: ball.vx * -1}
  end

  defp out_of_bounds_x?(new_ball, _prev_ball, _viewport_width), do: new_ball

  defp out_of_bounds_y?(
         %__MODULE__{circle: %Circle{y: y, radius: radius}} = ball,
         prev_ball
       )
       when y < radius do
    next_pos = %{ball.circle | y: prev_ball.circle.y}
    %{ball | circle: next_pos, vy: ball.vy * -1}
  end

  defp out_of_bounds_y?(new_ball, _prev_ball), do: new_ball
end
