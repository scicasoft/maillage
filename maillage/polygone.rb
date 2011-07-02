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
  
  def evaluer_zone_repere point
    @minx ||= point.x
    @miny ||= point.y
    @maxx ||= point.x
    @maxy ||= point.y
    @minx = [point.x, @minx].min
    @maxx = [point.x, @maxx].max
    @miny = [point.y, @miny].min
    @maxy = [point.y, @maxy].max
  end

  def ajouter_point point
    @points << point
    evaluer_zone_repere point
  end
  
  def ajouter_point_maillage point
    @maillage_points ||= []
    @maillage_points << point.to_s
    @points << point
    evaluer_zone_repere point
  end

  def ajouter_triangle_maillage triangle
    @pas_maillage ||= 0
    @maillage_triangles ||= []
    @triangles ||= []
    @triangles << triangle
    @pas_maillage = [@pas_maillage, triangle.max_length].max
    @maillage_triangles << triangle.to_s#"#{triangle.p1.num} #{triangle.p2.num} #{triangle.p3.num}"
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
    @maillage_points = []
    @triangles.each do |t|
      @maillage_points << t.p1.to_s << t.p2.to_s << t.p3.to_s
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
    
    @maillage_triangles = @triangles.collect{|t| "#{tassoc[t.p1.to_s]} #{tassoc[t.p2.to_s]} #{tassoc[t.p3.to_s]}"}
  end  
  
  #utilisée par delaunay cette methode permet de modifier la position des triangles d'indices it1 et it2 avec it1 et it2 les numeros des deux points d'en face et it3 et it4 les numeros des points de la diagonale
  def delaunay_correction it1, it2, p1, p2, p3, p4
    t1, t2 = @triangles[it1], @triangles[it2]
    @point_to_triangles[t1.p1.num]-=[it1]
    @point_to_triangles[t1.p2.num]-=[it1]
    @point_to_triangles[t1.p3.num]-=[it1]
          
    @point_to_triangles[t2.p1.num]-=[it2]
    @point_to_triangles[t2.p2.num]-=[it2]
    @point_to_triangles[t2.p3.num]-=[it2]
    
    pA, pD, pB, pC = @points[p1-1], @points[p2-1], @points[p3-1], @points[p4-1]
    @triangles[it1] = Triangle.new([pA, pB, pD])
    @triangles[it2] = Triangle.new([pA, pC, pD])
    
    t1, t2 = @triangles[it1], @triangles[it2]
    @point_to_triangles[t1.p1.num]+=[it1]
    @point_to_triangles[t1.p2.num]+=[it1]
    @point_to_triangles[t1.p3.num]+=[it1]
          
    @point_to_triangles[t2.p1.num]+=[it2]
    @point_to_triangles[t2.p2.num]+=[it2]
    @point_to_triangles[t2.p3.num]+=[it2]
  end
  
  #transforme le maillage en maillage de type delaunay
  #30 => 30 secondes
  def delaunay
    restart = false
    @point_to_triangles = identifier_triangle_points

    @triangles.length.times do |i|
      t = @triangles[i]
      t1 = @point_to_triangles[t.p1.num]-[i]
      t2 = @point_to_triangles[t.p2.num]-[i]
      t3 = @point_to_triangles[t.p3.num]-[i]
      
      rayon = t.rayon_cercle_circonscrit
      centre = t.centre_cercle_circonscrit

      unless (t1 & t2).empty?
        numt = (t1 & t2).first
        t_opp = @triangles[numt]
        pt = t.num_point_en_face t_opp
        if centre.distance(t_opp.points[pt]) < rayon
          delaunay_correction i, numt, t.p3.num, t_opp.points[pt].num, t.p1.num, t.p2.num
          restart = true
        end
      end

      unless (t1 & t3).empty?
        numt = (t1 & t3).first
        t_opp = @triangles[numt]
        pt = t.num_point_en_face t_opp
        if centre.distance(t_opp.points[pt]) < rayon
          delaunay_correction i, numt, t.p2.num, t_opp.points[pt].num, t.p1.num, t.p3.num
          restart = true
        end
      end
      
      unless (t2 & t3).empty?
        numt = (t2 & t3).first
        t_opp = @triangles[numt]
        pt = t.num_point_en_face t_opp
        if centre.distance(t_opp.points[pt]) < rayon
          delaunay_correction i, numt, t.p1.num, t_opp.points[pt].num, t.p2.num, t.p3.num
          restart = true
        end
      end
    end
    delaunay if restart
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
  
  private
  
  #permet d'itentifier pour chaque point les triangles qui l'utilisent
  def identifier_triangle_points
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
    return point_to_triangles
  end
end