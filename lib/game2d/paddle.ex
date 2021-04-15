defmodule Breakout.Game2D.Paddle do
  alias Breakout.Game2D.Rect

  @enforce_keys [:rect, :moving_left, :moving_right, :speed]
  defstruct [:rect, :moving_left, :moving_right, :speed]

  def new(x: x, y: y, width: width, height: height, speed: speed) do
    %__MODULE__{
      rect: Rect.new(x: x, y: y, width: width, height: height),
      moving_right: false,
      moving_left: false,
      speed: speed
    }
  end

  def rect(%__MODULE__{} = paddle) do
    paddle.rect
  end

  def translate(%__MODULE__{} = paddle) do
    {paddle.rect.x, paddle.rect.y}
  end

  def dimensions(%__MODULE__{} = paddle) do
    {paddle.rect.width, paddle.rect.height}
  end

  def should_move_paddle?(key, %__MODULE__{} = paddle) do
    case key do
      "left" ->
        %__MODULE__{paddle | moving_left: true, moving_right: false}

      "right" ->
        %__MODULE__{paddle | moving_right: true, moving_left: false}

      _ ->
        paddle
    end
  end

  def compute_next_position(%__MODULE__{} = paddle, viewport_width) do
    cond do
      paddle.moving_left ->
        next_pos = %{paddle.rect | x: max(0, paddle.rect.x - paddle.speed)}
        %{paddle | rect: next_pos}

      paddle.moving_right ->
        next_pos = %{
          paddle.rect
          | x: min(viewport_width - paddle.rect.width, paddle.rect.x + paddle.speed)
        }

        %{paddle | rect: next_pos}

      true ->
        paddle
    end
  end
end
