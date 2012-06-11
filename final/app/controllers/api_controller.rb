class ApiController < ApplicationController
  def index
    # Read data from XML
    file = File.new("config.xml", "r+")
    @xml = Nokogiri::XML(file)
    file.close

    @routes = {}   # <route_id, route result>

    # if agencies specified, load every route in the agency
    unless params[:agencies].nil?
      params[:agencies].split(",").each do |agency|
        rts = Agency.find_by_sql("select routes.route_id, agency.agency_name, agency.agency_url, routes.route_long_name, routes.route_url, routes.route_color from agency, routes where agency.agency_id='#{agency}' and routes.agency_id=agency.agency_id")
        rts.each do |route|
          unless @routes.key?(route.route_id)
            color = "#" + (route.route_color != nil && route.route_color.length == 6 ? route.route_color : generate_color())
            @routes[route.route_id] = route
            @routes[route.route_id].route_color = color
          end
        end
      end
    end

    # load single routes
    unless params[:routes].nil?
      params[:routes].split(",").each do |rt|
        rts = Agency.find_by_sql("select routes.route_id, agency.agency_name, agency.agency_url, routes.route_long_name, routes.route_url, routes.route_color from agency, routes where routes.route_id='#{rt}' and routes.agency_id=agency.agency_id")
        rts.each do |route|
          unless @routes.key?(route.route_id)
            color = "#" + (route.route_color != nil && route.route_color.length == 6 ? route.route_color : generate_color())
            @routes[route.route_id] = route
            @routes[route.route_id].route_color = color
          end
        end
      end
    end

    @showShapes = !params[:showShapes].nil?
    @shapes = {}

    # If showShapes was true, query all the shapes that lie on the loaded routes
    if @showShapes
      @routes.each do |rid, route|
        sps = Agency.find_by_sql("select distinct shapes.shape_id from shapes, trips where trips.route_id = '#{rid}' and trips.shape_id = shapes.shape_id")
        sps.each do |shape|
          unless @shapes.key?(shape.shape_id)
            pts = Agency.find_by_sql("select shape_pt_lon, shape_pt_lat from shapes where shape_id = '#{shape.shape_id}' order by convert(shape_pt_sequence, signed)")
            shp = Shape.new(shape.shape_id, route.route_color)
            pts.each do |pt|
              shp.points.push(LLPoint.new(pt.shape_pt_lat, pt.shape_pt_lon))
            end
            @shapes[shape.shape_id] = shp
          end
        end
      end
    end

    @stops = {}        # <stop_id, Stop>
    @connections = {}  # <stop_id, stop_id>
    dupstops = {}      # <stop_id, stop_id>, holds stop_ids that are duplicates in name

    # start at rediculous values and refine from there. For finding center point of map.
    @minlat = 500
    @maxlat = -500
    @minlon = 500
    @maxlon = -500

    # Load in stops
    @routes.each do |rid, route|
      # select all stops on route
      stop_ids = Agency.find_by_sql("select distinct stop_times.stop_id from stop_times, trips where trips.route_id='#{rid}' and stop_times.trip_id=trips.trip_id")
      stop_ids.each do |stop_id|
        stop = Agency.find_by_sql("select stop_id, stop_lat, stop_lon, stop_name, stop_desc, stop_url from stops where stop_id='#{stop_id.stop_id}'").first
        # Check if stop already added as part of another route or as a duplicate.
        if @stops.key?(stop.stop_id) || dupstops.key?(stop.stop_id)
          key = dupstops.key?(stop.stop_id) ? dupstops[stop.stop_id] : stop.stop_id
          unless @stops[key].routes.include?(rid)
            @stops[key].routes.push(rid)
          end
          next
        end

        # Create a duplicate entry if stop with that name already loaded.
        @stops.each do |id, st|
          if st.name == stop.stop_name
            dupstops[stop.stop_id] = id
            break
          end
        end

        # If all is well, now load in the stop.
        unless dupstops.key?(stop.stop_id)
          @minlat = stop.stop_lat.to_f if stop.stop_lat.to_f < @minlat
          @maxlat = stop.stop_lat.to_f if stop.stop_lat.to_f > @maxlat
          @minlon = stop.stop_lon.to_f if stop.stop_lon.to_f < @minlon
          @maxlon = stop.stop_lon.to_f if stop.stop_lon.to_f > @maxlon

          @stops[stop.stop_id] = Stop.new(stop.stop_id, LLPoint.new(stop.stop_lat, stop.stop_lon), stop.stop_name, stop.stop_desc, stop.stop_url)
          @stops[stop.stop_id].routes.push(rid)
        end
      end

      # Load in connections to be shown as straight lines on the map if showShapes not selected
      unless @showShapes
        trips = Agency.find_by_sql("select trip_id from trips where route_id='#{rid}'")
        trips.each do |trip|
          conns = Agency.find_by_sql("select stops.stop_id from stops, stop_times where trip_id='#{trip.trip_id}' and stop_times.stop_id=stops.stop_id order by stop_sequence")
          stps = []
          conns.each do |conn|
            stps.append(conn.stop_id) unless dupstops.key?(conn.stop_id)
          end
          (stps.length-1).times do |i|
            if @connections[stps[i]].nil?
              @connections[stps[i]] = []
            elsif !@connections[stps[i]].include?(stps[i+1]) && (@connections[stps[i+1]].nil? || !@connections[stps[i+1]].include?(stps[i]))
              @connections[stps[i]].append(stps[i+1])
            end
          end
        end
      end
    end

    @zoomlevel = 9

    latdiff = @maxlat - @minlat
    @zoomlevel = 13 if latdiff <= 0.05
    @zoomlevel = 12 if latdiff > 0.05
    @zoomlevel = 11 if latdiff > 0.1
    @zoomlevel = 10 if latdiff > 0.25
    @zoomlevel = 9 if latdiff > 0.5
    @zoomlevel = 8 if latdiff > 1
    @zoomlevel = 7 if latdiff > 2

    render :layout => false
  end
end

# Generate randomly different colors for different routes
def generate_color()
  res = ""
  n = [rand(50), rand(255), rand(255)].shuffle!
  3.times do |i|
    res += (n[i] < 16 ? "0" + n[i].to_s(16) : n[i].to_s(16))
  end
  return res
end

# Helper classes to store data
class Stop
  attr_accessor :id, :pt, :name, :desc, :url, :routes

  def initialize(id, pt, name, desc, url)
    @id = id
    @pt = pt
    @name = name
    @desc = desc == nil ? "" : desc
    @url = url == nil ? "" : url

    @routes = []
  end
end

class Shape
  attr_accessor :id, :points, :color

  def initialize (id, color)
    @id = id
    @color = color
    @points = []
  end
end

class LLPoint
  attr_accessor :lat, :lon

  def initialize(lat, lon)
    @lat = lat
    @lon = lon
  end
end
