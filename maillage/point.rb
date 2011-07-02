class Point
  attr_accessor :x, :y, :num

  def initialize(x, y, num=0)
    @x, @y, @num = x, y, num
  end

  def to_s
    "#{@x} #{@y}"
  end
  
  def distance p
    Math.sqrt((p.x-@x)*(p.x-@x)+(p.y-@y)*(p.y-@y))
  end
  
  def centre_segment p
    Point.new((@x+p.x)/2, (@y+p.y)/2)
  end
end

class String
  def to_point(num=0)
    Point.new(split[0].to_f, split[1].to_f, num)
  end
end