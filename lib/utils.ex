defmodule Utils do
  def intersects?(rect1, rect2) do
    rect1.x < rect2.x + rect2.width and
      rect1.y < rect2.y + rect2.height and
      rect1.x + rect1.width > rect2.x and
      rect1.y + rect1.height > rect2.y
  end

  def circle_to_rect(%{x: x, y: y, radius: radius}) do
    %{x: x - radius, y: y - radius, width: radius * 2 + 2, height: radius * 2 + 2}
  end

  # def intersection(rect1, rect2) do
  # left = return x(); }
  # right() const { return x() + width() - 1; }
  # top() const { return y(); }
  # bottom() const { return y() + height() - 1; }
  # end
end
