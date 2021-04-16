defmodule Breakout.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph

  import Scenic.Primitives
  alias Breakout.Game2D.{Ball, Paddle, Brick, Rect}

  @width 480
  @height 640
  @ball_speed 5
  @ball Ball.new(x: @width / 2, y: @height / 2, radius: 8, vx: @ball_speed, vy: @ball_speed)
  @paddle Paddle.new(
            x: @width / 2 - 40,
            y: @height - 18,
            width: 80,
            height: 16,
            speed: 5
          )
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
           circle_spec(Ball.radius(@ball),
             fill: :red,
             translate: Ball.translate(@ball),
             id: :ball
           ),
           rect_spec(Paddle.dimensions(@paddle),
             fill: :white,
             translate: Paddle.translate(@paddle),
             id: :paddle
           )
         ])

  def init(_, _opts) do
    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    bricks =
      for row <- 0..7,
          column <- 0..9,
          do:
            Brick.new(
              id: "brick_#{row}#{column}",
              x: @bricks_left_offset + column * @brick_width + column * @brick_spacing,
              y: @bricks_top_offset + row * @brick_height + row * @brick_spacing,
              width: @brick_width,
              height: @brick_height,
              color: Enum.at(@brick_colors, row)
            )

    new_graph =
      @graph
      |> add_specs_to_graph(
        bricks
        |> Enum.map(fn brick ->
          rect_spec(Brick.dimensions(brick),
            fill: brick.color,
            translate: Brick.translate(brick),
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
    new_paddle = Paddle.should_move_paddle?(key, state.paddle)
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
    new_paddle = Paddle.compute_next_position(paddle, state.width)
    %{state | paddle: new_paddle}
  end

  def compute_paddle_next_position(state) do
    state
  end

  defp render_next_frame(%{hurt: false, bricks: []} = state) do
    # TODO: You Win
  end

  defp render_next_frame(%{hurt: false, bricks: bricks} = state) do
    graph =
      state.graph
      |> Graph.modify(
        :ball,
        &circle(&1, Ball.radius(state.ball),
          fill: :red,
          translate: Ball.translate(state.ball),
          id: :ball
        )
      )
      |> Graph.modify(
        :paddle,
        &rect(&1, Paddle.dimensions(state.paddle),
          fill: :white,
          translate: Paddle.translate(state.paddle),
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
        &circle(&1, Ball.radius(@ball), fill: :red, translate: Ball.translate(@ball), id: :ball)
      )
      |> Graph.modify(
        :paddle,
        &rect(&1, Paddle.dimensions(@paddle),
          fill: :white,
          translate: Paddle.translate(@paddle),
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
    result =
      bricks
      |> Enum.filter(&(&1.dead != true))
      |> Enum.reduce(
        {false, [], nil},
        fn
          brick, {true, acc, b} ->
            {true, [brick | acc], b}

          brick, {false, acc, nil} ->
            ball_rect = Ball.to_rect(ball)
            intersection = Rect.intersection(ball_rect, Brick.rect(brick))

            case intersection do
              nil ->
                {false, [brick | acc], nil}

              _ ->
                dead_brick =
                  %{brick | dead: true}
                  |> IO.inspect(label: "dead brick:")

                new_ball_pos = Ball.deflect(ball, intersection)
                {true, [dead_brick | acc], new_ball_pos}
            end
        end
      )

    case result do
      {true, new_bricks, new_ball} ->
        %{state | bricks: new_bricks, ball: new_ball}

      {false, _, _} ->
        state
    end
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
    new_ball = Ball.compute_next_position(ball, state.width)
    %{state | ball: new_ball}
  end

  defp hurt?(%{ball: ball, lives: lives} = state) do
    case Ball.hurt?(ball, state.height) do
      true ->
        new_lives = lives - 1
        %{state | hurt: true, lives: new_lives}

      false ->
        state
    end
  end

  defp paddle_hit?(%{ball: ball, paddle: paddle} = state, prev_ball) do
    new_ball = Ball.paddle_hit?(ball, Paddle.rect(paddle), prev_ball)
    %{state | ball: new_ball}
  end
end
