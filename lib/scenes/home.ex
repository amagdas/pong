defmodule Breakout.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph

  import Scenic.Primitives
  import Utils

  @width 480
  @height 640
  @ball_speed 3
  @ball %{x: @width / 2, y: @height / 2, radius: 8, vx: @ball_speed, vy: @ball_speed}
  @paddle %{
    x: @width / 2 - 40,
    y: @height - 18,
    width: 80,
    height: 16,
    speed: 5,
    moving_right: false,
    moving_left: false
  }
  @frame_ms 32
  @brick_colors [:red, :blue, :dark_green, :brown, :yellow, :grey, :magenta, :cyan]
  @brick_width 40
  @brick_height 15
  @brick_spacing 3
  @bricks_left_offset 25
  @bricks_top_offset 45

  @graph Graph.build()
         |> add_specs_to_graph([
           rect_spec({@width, @height}),
           circle_spec(@ball.radius, fill: :red, translate: {@ball.x, @ball.y}, id: :ball),
           rect_spec({@paddle.width, @paddle.height},
             fill: :white,
             translate: {@paddle.x, @paddle.y},
             id: :paddle
           )
         ])

  def init(_, _opts) do
    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    bricks =
      for row <- 0..7,
          column <- 0..9,
          do: %{
            color: Enum.at(@brick_colors, row),
            width: @brick_width,
            height: @brick_height,
            x: @bricks_left_offset + column * @brick_width + column * @brick_spacing,
            y: @bricks_top_offset + row * @brick_height + row * @brick_spacing,
            dead: false,
            id: "brick_#{row}#{column}"
          }

    new_graph =
      @graph
      |> add_specs_to_graph(
        bricks
        |> Enum.map(fn brick ->
          rect_spec({brick.width, brick.height},
            fill: brick.color,
            translate: {brick.x, brick.y},
            id: brick.id
          )
        end)
      )

    state = %{
      width: @width,
      height: @height,
      graph: new_graph,
      ball: @ball,
      paddle: @paddle,
      bricks: bricks,
      frame_time: timer,
      lives: 3,
      hurt: false
    }

    {:ok, state, push: @graph}
  end

  def handle_input({:key, {key, type, _intensity}}, _context, state)
      when type in [:press, :release, :repeat] do
    new_paddle = should_move_paddle(key, state.paddle)
    new_state = %{state | paddle: new_paddle}
    {:noreply, new_state}
  end

  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  def handle_info(:frame, state) do
    new_state =
      state
      |> compute_ball_next_position()
      |> hurt?()
      |> paddle_hit?(state.ball)
      |> bricks_hit?()
      |> compute_paddle_next_position()
      |> render_next_frame()

    {:noreply, new_state, push: new_state.graph}
  end

  def compute_paddle_next_position(%{paddle: paddle, hurt: false} = state) do
    new_paddle =
      cond do
        paddle.moving_left ->
          %{paddle | x: max(0, paddle.x - paddle.speed)}

        paddle.moving_right ->
          %{paddle | x: min(@width - paddle.width, paddle.x + paddle.speed)}

        true ->
          paddle
      end

    %{state | paddle: new_paddle}
  end

  def compute_paddle_next_position(state) do
    state
  end

  defp render_next_frame(%{hurt: false, bricks: bricks} = state) do
    graph =
      state.graph
      |> Graph.modify(
        :ball,
        &circle(&1, @ball.radius, fill: :red, translate: {state.ball.x, state.ball.y}, id: :ball)
      )
      |> Graph.modify(
        :paddle,
        &rect(&1, {@paddle.width, @paddle.height},
          fill: :white,
          translate: {state.paddle.x, state.paddle.y},
          id: :paddle
        )
      )
      |> render_bricks(bricks)

    %{state | graph: graph}
  end

  defp render_next_frame(%{hurt: true} = state) do
    Logger.info("Lost a life!!! #{inspect(state.lives)}")

    state
    |> reset()
  end

  defp reset(state) do
    new_graph =
      state.graph
      |> Graph.modify(
        :ball,
        &circle(&1, @ball.radius, fill: :red, translate: {@ball.x, @ball.y}, id: :ball)
      )
      |> Graph.modify(
        :paddle,
        &rect(&1, {@paddle.width, @paddle.height},
          fill: :white,
          translate: {@paddle.x, @paddle.y},
          id: :paddle
        )
      )

    %{
      state
      | graph: new_graph,
        ball: @ball,
        paddle: @paddle,
        hurt: false
    }
  end

  defp bricks_hit?(%{bricks: bricks, ball: ball} = state) do
    {_found, new_bricks} =
      bricks
      |> Enum.filter(&(&1.dead != true))
      |> Enum.reduce(
        {false, []},
        fn
          brick, {true, acc} ->
            {true, [brick | acc]}

          brick, {false, acc} ->
            ball_rect = Utils.circle_to_rect(ball)
            intersected = Utils.intersects?(ball_rect, brick)

            case intersected do
              true ->
                dead_brick =
                  %{brick | dead: true}
                  |> IO.inspect(label: "dead brick:")

                {true, [dead_brick | acc]}

              _ ->
                {false, [brick | acc]}
            end
        end
      )

    %{state | bricks: new_bricks}
  end

  defp render_bricks(graph, bricks) do
    bricks
    |> Enum.reduce(graph, fn brick, acc ->
      case brick.dead do
        true ->
          Graph.delete(graph, brick.id)

        false ->
          acc
      end
    end)
  end

  defp compute_ball_next_position(%{ball: ball} = state) do
    new_ball =
      %{ball | x: ball.x + ball.vx, y: ball.y + ball.vy}
      |> ball_out_of_bounds_x?(ball)
      |> ball_out_of_bounds_y?(ball)

    # |> IO.inspect(label: "ball next pos:")

    %{state | ball: new_ball}
  end

  defp ball_out_of_bounds_x?(%{x: x, radius: radius} = new_ball, prev_ball)
       when x < radius or x > @width - radius do
    %{new_ball | x: prev_ball.x, vx: new_ball.vx * -1}
  end

  defp ball_out_of_bounds_x?(new_ball, _prev_ball), do: new_ball

  defp ball_out_of_bounds_y?(%{y: y, radius: radius} = new_ball, prev_ball)
       when y < radius do
    %{new_ball | y: prev_ball.y, vy: new_ball.vy * -1}
  end

  defp ball_out_of_bounds_y?(new_ball, _prev_ball), do: new_ball

  defp hurt?(%{ball: %{y: y, radius: radius}, lives: lives} = state)
       when y > @height - radius do
    new_lives = lives - 1
    %{state | hurt: true, lives: new_lives}
  end

  defp hurt?(state), do: state

  defp should_move_paddle(key, paddle) do
    case key do
      "left" ->
        %{paddle | moving_left: true, moving_right: false}

      "right" ->
        %{paddle | moving_right: true, moving_left: false}

      _ ->
        paddle
    end
  end

  defp paddle_hit?(%{ball: ball, paddle: paddle} = state, prev_ball) do
    case ball
         |> Utils.circle_to_rect()
         |> Utils.intersects?(paddle) do
      true ->
        new_ball = %{ball | y: prev_ball.y, vy: ball.vy * -1}
        %{state | ball: new_ball}

      _ ->
        state
    end
  end
end
