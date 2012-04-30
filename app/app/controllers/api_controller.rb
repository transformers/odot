require "nokogiri"
require "mysql"

class ApiController < ActionController::Base
  def route_map
    @error = params[:routes].nil?

    unless @error
      file = File.new("../../proj/script/config.xml", "r+")
      @xml = Nokogiri::XML(file)
      file.close
      @dbinfo = @xml.at_css("gtfs database")

      @dberror = false
      begin
        db = Mysql.new(@dbinfo["host"], @dbinfo["user"], @dbinfo["pass"], @dbinfo["dbname"])

        @routes = []
        @showShapes = false
        params[:routes].split(",").each do |route|
          strs = route.split("#")
          rt = Route.new(strs[0], strs[1])

          stops = db.query("select stop_id, stop_lat, stop_lon from stops where stop_id in (select stop_id from stop_times where trip_id in (select trip_id from trips where route_id='#{rt.name}'))")
          stops.each do |stop|
            rt.stops[stop[0]] = LLPoint.new(stop[1], stop[2])
          end

          query = "select trip_id, shape_id from trips where route_id='#{rt.name}'"
          trips = db.query("select trip_id, shape_id from trips where route_id='#{rt.name}'")
          trips.each do |trip|
            conns = db.query("select trip_id, stop_id from stop_times where trip_id='#{trip[0]}' order by stop_sequence")
            rows = []
            conns.each do |conn|
              rows.append(conn)
            end
            i=0
            (rows.length-1).times do
              if rt.connections[rows[i][1]].nil?
                rt.connections[rows[i][1]] = [rows[i+1][1]]
              elsif (i != rows.length-1) && (not rt.connections[rows[i][1]].include?(rows[i+1][1])) && ((rt.connections[rows[i+1][1]].nil?) || (not rt.connections[rows[i+1][1]].include?(rows[i][1])))
                rt.connections[rows[i][1]].append(rows[i+1][1])
              end
              i = i+1
            end
          end
          @routes.append(rt)
        end


      #  @trips = db.query("select trip_id from trips where route_id = '#{params[:route]}'")
      #  @shapes = []
      #  @trips.each do |trip|
      #    str = trip[0]
      #    @shapes.append(db.query("select shape_pt_lon, shape_pt_lat from shapes, trips where trips.shape_id = shapes.shape_id and trips.trip_id = '#{trip[0]}' order by convert(shape_pt_sequence, signed)") )
      #  end
      #rescue
      #  @dberror = true
      #end
      end
    end
  end
end