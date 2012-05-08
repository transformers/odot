require "nokogiri"
require "mysql"

class MapController < ActionController::Base
  def show
    file = File.new("../script/config.xml", "r+")
    @xml = Nokogiri::XML(file)
    file.close

    @dbinfo = @xml.at_css("gtfs database")

    @dberror = false
    begin
      db = Mysql.new(@dbinfo["host"], @dbinfo["user"], @dbinfo["pass"], @dbinfo["dbname"])
      @agencies = db.query("select * from agency")
      @routes = db.query("select route_id, agency_id, route_long_name from routes")
    rescue
      @dberror = true
    ensure
      db.close()
    end

    def update_route_select
      routes = Route.where(:agency_id=>params[:agency_id]).order(:agency_name) unless params[:agency_id].blank?
      render :partial => "routes", :locals => { :routes => routes }
    end

    render :layout => "application"
  end
end
