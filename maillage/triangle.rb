class Triangle

  #un tableau contenant les trois points du triangle sous forme d'objet Point
  attr_accessor :points, :centre_cc

  def initialize(points)
    @points = points
  end

  def to_s
    "#{p1.num} #{p2.num} #{p3.num}"
  end
  
  def p1
    @points[0]
  end
  
  def p2
    @points[1]
  end
  
  def p3
    @points[2]
  end
  
  def centre_cercle_circonscrit
    pA, pB, pC = p1, p2, p3
    
    pA, pB, pC = p3, p2, p1 if pA.y == pB.y
    
    pA, pB, pC = p2, p3, p1 if pA.y == pC.y
    
    xA, yA = pA.x, pA.y
    xB, yB = pB.x, pB.y
    xC, yC = pC.x, pC.y
    
    xI, yI = pA.centre_segment(pB).x, pA.centre_segment(pB).y
    xJ, yJ = pA.centre_segment(pC).x, pA.centre_segment(pC).y
    
    x = (xI*((xA-xB)/(yB-yA))-xJ*((xA-xC)/(yC-yA))-yI+yJ) / (((xA-xB)/(yB-yA))-((xA-xC)/(yC-yA)))
    y = yI+(x-xI)*((xA-xB)/(yB-yA))
    
    Point.new(x, y)
  end
  
  def rayon_cercle_circonscrit
    centre_cercle_circonscrit.distance(p1)
  end
  
  def cercle_circonscrit_contient_point? p
    p.distance(centre_cercle_circonscrit) < rayon_cercle_circonscrit
  end
  
  def num_point_en_face t
    tab = [p1.num, p2.num, p3.num]
    return 0 unless tab.include?(t.p1.num)
    return 1 unless tab.include?(t.p2.num)
    return 2 unless tab.include?(t.p3.num)
    return -1
  end
  
  def max_length
    [p1.distance(p2), p1.distance(p3), p2.distance(p3)].max
  end
  
  def mailler(p = 10)
    triangles = []
    dx = (p3.x-p1.x)/p
    dy = (p2.y-p1.y)/p
    
    0.upto(p-1) do |j|
      0.upto(p-j-1) do |i|
        x = p1.x+(p2.x-p1.x)*i/p+dx*j
        y = p1.y+(p3.y-p1.y)*j/p+dy*i
        triangles << Triangle.new([Point.new(x, y),
                                   Point.new(x+(p2.x-p1.x)/p, y+dy),
                                   Point.new(x+dx, y+(p3.y-p1.y)/p)])
      end
    end    
    
    0.upto(p-2) do |j|
      0.upto(p-j-2) do |i|
        x = p1.x+(p2.x-p1.x)*i/p+dx*j
        y = p1.y+(p3.y-p1.y)*j/p+dy*i
        triangles << Triangle.new([Point.new(x+(p2.x-p1.x)/p, y+dy),
                                   Point.new(x+dx, y+(p3.y-p1.y)/p),
                                   Point.new(x+(p2.x-p1.x)/p+dx, y+(p3.y-p1.y)/p+dy)])
      end
    end
    
    return triangles
  end

  def to_graphe_js
    code = "contexte.moveTo(X(#{@points[0].x}, #{@points[0].y}), Y(#{@points[0].x}, #{@points[0].y}));"
    code += "contexte.lineTo(X(#{@points[1].x}, #{@points[1].y}), Y(#{@points[1].x}, #{@points[1].y}));"
    code += "contexte.lineTo(X(#{@points[2].x}, #{@points[2].y}), Y(#{@points[2].x}, #{@points[2].y}));"
    code += "contexte.lineTo(X(#{@points[0].x}, #{@points[0].y}), Y(#{@points[0].x}, #{@points[0].y}));"
  end
  
  def tracer_cercle_circonscrit
    ccc = centre_cercle_circonscrit
    "circle(#{ccc.x}, #{ccc.y}, #{ccc.distance(p1)});"
  end

end