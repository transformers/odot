require "nokogiri"

class ConfigController < ApplicationController
  def index
    file = File.new("../script/config.xml", "r+")
    @xml = Nokogiri::XML(file)
    file.close

    session[:uname] = params[:uname] unless params[:uname].nil?
    session[:pword] = params[:pword] unless params[:pword].nil?

    @authenticated = false
    @warn = false
    unless (session[:uname].nil? || session[:pword].nil?)
      @xml.css("gtfs user").each do |user|
        if(user['name'] == session[:uname] && user['pass'] == session[:pword])
          @authenticated = true
          break
        end
      end
      @warn = true unless @authenticated
    end

    if @authenticated
      unless params[:addfeed].nil?
        feed_node = @xml.css("gtfs entry").last
        new_node = Nokogiri::XML::Node.new "entry", @xml
        new_node["agency"] = params[:agency]
        new_node["dirname"] = params[:dirname]
        new_node["url"] = params[:url]
        new_node["active"] = params[:active].nil? ? "0" : "1"
        feed_node.add_next_sibling(new_node)
        File.open("../script/config.xml", 'w') {|f| f.write(@xml.to_xml) }
        #redirect_to "config"
      end

      unless params[:savefeed].nil?
        feed_node = @xml.at_css("gtfs entry[dirname=\"#{params[:savefeed]}\"]")
        feed_node["agency"] = params[:agency]
        feed_node["dirname"] = params[:dirname]
        feed_node["url"] = params[:url]
        feed_node["active"] = params[:active].nil? ? "0" : "1"
        File.open("../script/config.xml", 'w') {|f| f.write(@xml.to_xml) }
        #redirect_to "config"
      end

      unless params[:delfeed].nil?
        @xml.at_css("gtfs entry[dirname=\"#{params[:delfeed]}\"]").remove
        File.open("../script/config.xml", 'w') {|f| f.write(@xml.to_xml) }
        #redirect_to "config"
      end

      @edit = params[:edit]
      @editfeed = params[:editfeed]
    else
      # show login screen
    end
  end
end