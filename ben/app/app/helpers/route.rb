class LLPoint
  attr_accessor :lat, :lon

  def initialize(lat, lon)
    @lat = lat
    @lon = lon
  end
end

class Shape
  attr_accessor :name, :points

  def initialize(name)
    @name = name
    @points = []
  end
end

class Route
  attr_accessor :agency, :agencyname, :name, :longname, :url, :color

  def initialize(agency, agencyname, name, longname, url, color)
    @agency = agency
    @agencyname = agencyname
    @name = name
    @longname = longname
    @url = url
    @color = color
  end
end

class Stop
  attr_accessor :id, :pt, :name, :desc, :url, :routes

  def initialize(id, pt, name, desc, url)
    @id = id
    @pt = pt
    @name = name
    @desc = desc
    @url = url

    @routes = []
  end
end