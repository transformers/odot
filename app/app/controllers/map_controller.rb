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
      @agencies = db.query("SELECT agency_id,
CASE WHEN LENGTH(TRIM(agency_name))>33 THEN CONCAT(LEFT(TRIM(agency_name), 30),'...') ELSE TRIM(agency_name) END FROM agency")
      @routes = db.query("SELECT route_id, agency_id, route_short_name,
CASE WHEN LENGTH(TRIM(route_long_name))>33 THEN CONCAT(LEFT(TRIM(route_long_name), 30),'...') ELSE TRIM(route_long_name) END FROM routes")
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
