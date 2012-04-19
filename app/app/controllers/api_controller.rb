require "nokogiri"
require "mysql"

class ApiController < ActionController::Base
  def route_map
    @error = params[:agency].nil? || params[:route].nil?

    file = File.new("../../proj/script/config.xml", "r+")
    @xml = Nokogiri::XML(file)
    file.close
    @dbinfo = @xml.at_css("gtfs database")

    @dberror = false
    begin
      db = Mysql.new(@dbinfo["host"], @dbinfo["user"], @dbinfo["pass"], @dbinfo["dbname"])
      @stops = db.query("select stop_lat, stop_lon from stops where stop_id in (select stop_id from stop_times where trip_id in (select trip_id from trips where route_id='#{params[:route]}'))")
      @trips = db.query("select trip_id from trips where route_id = '#{params[:route]}'")
      @shapes = []
      @trips.each do |trip|
        str = trip[0]
        @shapes.append(db.query("select shape_pt_lon, shape_pt_lat from shapes, trips where trips.shape_id = shapes.shape_id and trips.trip_id = '#{trip[0]}' order by convert(shape_pt_sequence, signed)") )
      end
    rescue
      @dberror = true
    end
  end
end