require "nokogiri"

class ConfigController < ApplicationController
  def index
    file = File.new("config.xml", "r+")
    @xml = Nokogiri::XML(file)
    file.close

    cookies[:uname] = params[:uname] unless params[:uname].nil?
    cookies[:pword] = params[:pword] unless params[:pword].nil?

    @authenticated = false
    @warn = false
    unless (cookies[:uname].nil? || cookies[:pword].nil?)
      @xml.css("gtfs user").each do |user|
        if(user['name'] == cookies[:uname] && user['pass'] == cookies[:pword])
          @authenticated = true
          break
        end
      end
      @warn = true unless @authenticated
    end

    if @authenticated
      unless params[:adduser].nil?
        feed_node = @xml.css("gtfs user").last
        new_node = Nokogiri::XML::Node.new "user", @xml
        new_node["name"] = params[:name]
        new_node["pass"] = params[:pass]
        feed_node.add_next_sibling(new_node)
        File.open("config.xml", 'w') {|f| f.write(@xml.to_xml) }
      end

      unless params[:addfeed].nil?
        feed_node = @xml.css("gtfs entry").last
        new_node = Nokogiri::XML::Node.new "entry", @xml
        new_node["agency"] = params[:agency]
        new_node["dirname"] = params[:dirname]
        new_node["url"] = params[:url]
        new_node["active"] = params[:active].nil? ? "0" : "1"
        new_node["update"] = params[:update].nil? ? "0" : "1"
        feed_node.add_next_sibling(new_node)
        File.open("config.xml", 'w') {|f| f.write(@xml.to_xml) }
      end

      unless params[:savefeed].nil?
        feed_node = @xml.at_css("gtfs entry[dirname=\"#{params[:savefeed]}\"]")
        feed_node["agency"] = params[:agency]
        feed_node["dirname"] = params[:dirname]
        feed_node["url"] = params[:url]
        feed_node["active"] = params[:active].nil? ? "0" : "1"
        feed_node["update"] = params[:update].nil? ? "0" : "1"
        File.open("config.xml", 'w') {|f| f.write(@xml.to_xml) }
      end

      unless params[:deluser].nil?
        @xml.at_css("gtfs user[name=\"#{params[:deluser]}\"]").remove
        File.open("config.xml", 'w') {|f| f.write(@xml.to_xml) }
      end

      unless params[:delfeed].nil?
        @xml.at_css("gtfs entry[dirname=\"#{params[:delfeed]}\"]").remove
        File.open("config.xml", 'w') {|f| f.write(@xml.to_xml) }
      end

      @edit = params[:edit]
      @editfeed = params[:editfeed]
    else
      # show login screen
    end

    @scriptrun = false
    unless (params[:runscript].nil?)
      system "python script.py > output.txt 2>&1"
      @scriptrun = true
    end
  end

  def output
    file = File.new("output.txt")
    @lines = file.readlines()
    file.close
  end
end