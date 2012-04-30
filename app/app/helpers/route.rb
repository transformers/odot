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
  attr_accessor :agency, :name, :stops, :connections, :shapes

  def initialize(agency, name)
    @agency = agency
    @name = name
    @stops = {}
    @shapes = []
    @connections = {}
  end
end