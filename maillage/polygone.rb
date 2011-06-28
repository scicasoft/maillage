class Polygone
  attr_accessor :points,
                :triangles,
                :maillage_points,
                :maillage_triangles,
                :minx,
                :miny,
                :maxx,
                :maxy,
                :p,
                :pas_maillage,
                :frontiere
  
  def initialize(points = [])
    @points = points
  end

  def ajouter_point point
    @points << point
  end
  
  def ajouter_point_maillage point
    @maillage_points ||= []
    @maillage_points << point.to_s
    @points << point
    @minx ||= point.x
    @miny ||= point.y
    @maxx ||= point.x
    @maxy ||= point.y
    @minx = [point.x, @minx].min
    @maxx = [point.x, @maxx].max
    @miny = [point.y, @miny].min
    @maxy = [point.y, @maxy].max
  end

  def ajouter_triangle_maillage triangle
    @pas_maillage ||= 0
    @maillage_triangles ||= []
    @triangles ||= []
    @triangles << triangle
    @pas_maillage = [@pas_maillage, triangle.max_length].max
    @maillage_triangles << "#{triangle.p1.num} #{triangle.p2.num} #{triangle.p3.num}"
  end
  
  def decoupage_triangles
    nb_triangles = @points.length-2
    triangles = []
    long_max = 0
    nb_triangles.times do |i|
      triangles << Triangle.new([@points[0], @points[i+1], @points[i+2]])
      long_max = [long_max, triangles.last.max_length].max
    end
    return triangles, long_max
  end

  def mailler(config)
    triangles, long_max = decoupage_triangles
    
    @p = config[:p]
    @pas_maillage = @p.nil? ? config[:pas_maillage] : long_max/@p
    @p ||= (long_max/@pas_maillage).to_i+1
    
    @triangles = []
    triangles.each {|t| @triangles += t.mailler(@p)}
    
    t = @triangles.first
    @minx, @miny, @maxx, @maxy = t.p1.x, t.p1.y, t.p1.x, t.p1.y
    @maillage_points = []
    @triangles.each do |t|
      @maillage_points << t.p1.to_s << t.p2.to_s << t.p3.to_s
      @minx = [t.p1.x, t.p2.x, t.p3.x, @minx].min
      @maxx = [t.p1.x, t.p2.x, t.p3.x, @maxx].max
      @miny = [t.p1.y, t.p2.y, t.p3.y, @miny].min
      @maxy = [t.p1.y, t.p2.y, t.p3.y, @maxy].max
    end
    @maillage_points.uniq!
    @points = []
    tassoc = {}
    @maillage_points.length.times do |i|
      @points << @maillage_points[i].to_point(i+1)
      tassoc[@maillage_points[i]] = i+1
    end
    
    @triangles.length.times do |i|
      @triangles[i].points[0] = @points[tassoc[@triangles[i].p1.to_s]-1]
      @triangles[i].points[1] = @points[tassoc[@triangles[i].p2.to_s]-1]
      @triangles[i].points[2] = @points[tassoc[@triangles[i].p3.to_s]-1]
    end
    
    @maillage_triangles = @triangles.collect{|t| "#{@maillage_points.index(t.p1.to_s)+1} #{@maillage_points.index(t.p2.to_s)+1} #{@maillage_points.index(t.p3.to_s)+1}"}
  end
  
  def determiner_frontiere
    point_to_triangles = []
    (@maillage_points.length+1).times do
      point_to_triangles << []
    end
    @triangles.length.times do |i|
      t = @triangles[i]
      point_to_triangles[t.p1.num] << i
      point_to_triangles[t.p2.num] << i
      point_to_triangles[t.p3.num] << i
    end
  end
  
  def delaunay
    point_to_triangles = []
    (@maillage_points.length+1).times do
      point_to_triangles << []
    end
    @triangles.length.times do |i|
      t = @triangles[i]
      point_to_triangles[t.p1.num] << i
      point_to_triangles[t.p2.num] << i
      point_to_triangles[t.p3.num] << i
    end

    @triangles.length.times do |i|
      t = @triangles[i]
      tab = [t.p1.num, t.p2.num, t.p3.num]
      t1 = point_to_triangles[t.p1.num]-[i]
      t2 = point_to_triangles[t.p2.num]-[i]
      t3 = point_to_triangles[t.p3.num]-[i]

      unless (t1 & t2).empty?
        numt = (t1 & t2).first
        t_opp = @triangles[numt]
        pt = 0 unless tab.include?(t_opp.p1.num)
        pt = 1 unless tab.include?(t_opp.p2.num)
        pt = 2 unless tab.include?(t_opp.p3.num)
        centre = t.centre_cercle_circonscrit
        if t_opp.points[pt].distance(centre) < t.p1.distance(centre)
          pA, pB, pC, pD = @points[t.p3.num-1], @points[t.p1.num-1], @points[t.p2.num-1], @points[t_opp.points[pt].num-1]
          @triangles[i] = Triangle.new([pA, pB, pD])
          @triangles[numt] = Triangle.new([pA, pC, pD])
          return delaunay
        end
      end

      unless (t1 & t3).empty?
        numt = (t1 & t3).first
        t_opp = @triangles[numt]
        pt = 0 unless tab.include?(t_opp.p1.num)
        pt = 1 unless tab.include?(t_opp.p2.num)
        pt = 2 unless tab.include?(t_opp.p3.num)
        centre = t.centre_cercle_circonscrit
        if t_opp.points[pt].distance(centre) < t.p1.distance(centre)
          pA, pB, pC, pD = @points[t.p2.num-1], @points[t.p1.num-1], @points[t.p3.num-1], @points[t_opp.points[pt].num-1]
          #pA, pB, pC, pD = t.p2, t.p1, t.p3, t_opp.points[pt]
          @triangles[i] = Triangle.new([pA, pB, pD])
          @triangles[numt] = Triangle.new([pA, pC, pD])
          return delaunay
        end
      end
      
      unless (t2 & t3).empty?
        numt = (t2 & t3).first
        t_opp = @triangles[numt]
        pt = 0 unless tab.include?(t_opp.p1.num)
        pt = 1 unless tab.include?(t_opp.p2.num)
        pt = 2 unless tab.include?(t_opp.p3.num)
        centre = t.centre_cercle_circonscrit
        if t_opp.points[pt].distance(centre) < t.p1.distance(centre)
          pA, pB, pC, pD = @points[t.p1.num-1], @points[t.p2.num-1], @points[t.p3.num-1], @points[t_opp.points[pt].num-1]
          #pA, pB, pC, pD = t.p1, t.p2, t.p3, t_opp.points[pt]
          @triangles[i] = Triangle.new([pA, pB, pD])
          @triangles[numt] = Triangle.new([pA, pC, pD])
          return delaunay
        end
      end
    end
  end

  def to_graphe_js
    @triangles.collect{|t| t.to_graphe_js }.to_s
  end
  
  def self.get_points_html taille
    html = ""
    taille.times do
      html += "<table class='coord'>"
      html += "<tr><td class='coord_x'><input size='4' type='number' name='x[]' value='1'></td></tr>"
      html += "<tr><td class='coord_y'><input size='4' type='number' name='y[]' value='1'></td></tr>"
      html += "</table>"
    end
    html
  end
end