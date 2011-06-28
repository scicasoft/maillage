get '/style.css' do
  sass :style, :style => :expanded
end

get '/' do
  erb :index
end

get '/ajout_objet' do
  erb :ajout_objet
end

post '/mailler' do  
  @taille, choix, @polygone = params[:nombre_point].to_i, params[:pas], Polygone.new
  
  @taille.times do |i|
    @polygone.ajouter_point Point.new(params[:x][i].to_f, params[:y][i].to_f)
  end
  
  t1 = Time.now
  
  choix == "1" ? @polygone.mailler({:pas_maillage => params[:pas_maillage].to_f}) : @polygone.mailler({:p => params[:p].to_i})
  
  @polygone.delaunay if params[:delaunay] == "1"
  
  fts, fps = File.open("sortie/sortie_triangles.txt", 'w'), File.open("sortie/sortie_points.txt", 'w')
  
  @polygone.maillage_triangles.each { |t| fts.puts t }
  fts.close
  
  @polygone.maillage_points.each { |p| fps.puts p }
  fps.close
  
  t2 = Time.now
  
  @duree = t2-t1
  chargement_parametre_repere
  
  erb :mailler
end

get '/get_points/:taille' do
  @taille = params[:taille].to_i
  erb :get_points, :layout => false
end

get '/formchargement' do
  erb :formchargement
end

post '/chargement' do
  fts, fps = File.open("sortie/#{params[:fichier_triangles]}", 'r'), File.open("sortie/#{params[:fichier_points]}", 'r')
  
  @polygone = Polygone.new
  
  t1 = Time.now
  
  i=0
  fps.each_line { |l|
    i+=1
    @polygone.ajouter_point_maillage l.to_point(i)
  }
  
  fts.each_line { |l|
    n1, n2, n3 = l.split[0].to_i-1, l.split[1].to_i-1, l.split[2].to_i-1
    @polygone.ajouter_triangle_maillage Triangle.new([@polygone.points[n1], @polygone.points[n2], @polygone.points[n3]])
  }
  
  @polygone.delaunay if params[:delaunay] == "1"
  
  t2 = Time.now
  
  @duree = t2-t1
  
  chargement_parametre_repere
  
  erb :chargement
end

def chargement_parametre_repere
  #longueur de la zone de dessin en pixel
  @longueur = (params[:longueur] || 500).to_f
  #hauteur de la zone de dessin en pixel
  @hauteur = (params[:hauteur] || 500).to_f
  #le X min
  @minX = (@polygone.minx || -10).to_f
  #le X max
  @maxX = (@polygone.minx+[@polygone.maxx-@polygone.minx, @polygone.maxy-@polygone.miny].max || 10).to_f
  #le Y min
  @minY = (@polygone.miny || -5).to_f
  #le Y max
  @maxY = (@polygone.miny+[@polygone.maxx-@polygone.minx, @polygone.maxy-@polygone.miny].max || 5).to_f
end