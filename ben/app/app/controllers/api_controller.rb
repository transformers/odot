require "nokogiri"
require "mysql"

class ApiController < ActionController::Base
  def route_map
    file = File.new("../../proj/script/config.xml", "r+")
    @xml = Nokogiri::XML(file)
    file.close
    @dbinfo = @xml.at_css("gtfs database")

    db = Mysql.new(@dbinfo["host"], @dbinfo["user"], @dbinfo["pass"], @dbinfo["dbname"])

    @routes = {}

    unless params[:agencies].nil?
      params[:agencies].split(",").each do |agency|
        rts = db.query("select routes.id, routes.route_id, agency.agency_name, routes.route_long_name, routes.route_url, routes.route_color from agency, routes where agency.agency_id='#{agency}' and routes.agency_id=agency.agency_id")
        rts.each do |route|
          unless @routes.key?(route[0])
            color = "#" + (route[5].length == 6 ? route[5] : generate_color())
            @routes[route[0]] = Route.new(agency, route[2], route[1], route[3], route[4], color)
          end
        end
      end
    end

    unless params[:routes].nil?
      params[:routes].split(",").each do |rt|
        pair = rt.split(".")
        rts = db.query("select routes.id, routes.route_id, agency.agency_name, routes.route_long_name, routes.route_url, routes.route_color from agency, routes where routes.route_id='#{pair[1]}' and agency_agency_id='#{pair[0]}' and routes.agency_id=agency.agency_id")
        rts.each do |route|
          unless @routes.key?(route[0])
            color = "#" + (route[5].length == 6 ? route[5] : generate_color())
            @routes[route[0]] = Route.new(agency, route[2], route[1], route[2], route[3], color)
          end
        end
      end
    end

    @showShapes = !params[:showShapes].nil?
    @shapes = {}

    if @showShapes
      @routes.each do |rid, route|
        sps = db.query("select distinct shapes.id, shapes.shape_id from shapes, trips where trips.route_id = '#{route.name}' and trips.shape_id = shapes.shape_id")
        sps.each do |shape|
          unless @shapes.key?(shape[0])
            pts = db.query("select id, shape_pt_lon, shape_pt_lat from shapes where shape_id = '#{shape[1]}' order by convert(shape_pt_sequence, signed)")
            shp = Shape.new(shape[1])
            pts.each do |pt|
              shp.points.push(LLPoint.new(pt[2], pt[1]))
            end
            #@shapes[shape[0]] = shp
          end
        end
      end
    end

    @stops = {}
    @connections = {}

    dupstops = {}

    @routes.each do |rid, route|
      stops = db.query("select id, stop_id, stop_lat, stop_lon, stop_name, stop_desc, stop_url from stops where stop_id in (select stop_id from stop_times where trip_id in (select trip_id from trips where route_id='#{route.name}'))")
      stops.each do |stop|
        if @stops.key?(stop[0]) || dupstops.key?(stop[0])
          key = dupstops.key?(stop[0]) ? dupstops[stop[0]] : stop[0]
          unless @stops[key].routes.include?(rid)
            @stops[key].routes.push(rid)
          end
          next
        end

        @stops.each do |id, st|
          if st.name == stop[4]
            dupstops[stop[0]] = id
            break
          end
        end

        unless dupstops.key?(stop[0])
          @stops[stop[0]] = Stop.new(stop[1], LLPoint.new(stop[2], stop[3]), stop[4], stop[5], stop[6])
          @stops[stop[0]].routes.push(rid)
        end
      end

      unless @showShapes
        trips = db.query("select trip_id from trips where route_id='#{route.name}'")
        trips.each do |trip|
          conns = db.query("select stops.id from stops, stop_times where trip_id='#{trip[0]}' and stop_times.stop_id=stops.stop_id order by stop_sequence")
          stps = []
          conns.each do |conn|
            stps.append(conn[0])
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
    a = 5;
    b = a + 5
  end
end

def generate_color()
  res = ""
  n = [rand(50), rand(255), rand(255)].shuffle!
  3.times do |i|
    res += (n[i] < 16 ? "0" + n[i].to_s(16) : n[i].to_s(16))
  end
  return res
end