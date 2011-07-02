class Segment
  attr_accessor :a, :b

  def initialize(a, b)
    @a = a
    @b = b
  end

  def to_graphe_js
    code = "contexte.moveTo(X(#{@a.x}, #{@a.y}), Y(#{@a.x}, #{@a.y}));"
    code += "contexte.lineTo(X(#{@b.x}, #{@b.y}), Y(#{@b.x}, #{@b.y}));"
  end
end