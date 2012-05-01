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
    rescue
      @dberror = true
    ensure
      db.close()
    end

    render :layout => "application"
  end
end

