require "nokogiri"
require "mysql"

class ConfigController < ActionController::Base
  def show
    file = File.new("../../proj/script/config.xml", "r+")
    @xml = Nokogiri::XML(file)
    file.close

    session[:uname] = params[:uname] unless params[:uname].nil?
    session[:passw] = params[:passw] unless params[:passw].nil?

    @authenticated = false
    @warn = false
    unless (session[:uname].nil? || session[:passw].nil?)
      @xml.css("gtfs user").each do |user|
        if(user['name'] == session[:uname] && user['pass'] == session[:passw])
          @authenticated = true
          break
        end
      end
      @warn = true unless @authenticated
    end

    if @authenticated
      unless params[:save].nil?
        db_node = @xml.at_css("gtfs database")
        db_node["host"] = params[:host]
        db_node["user"] = params[:user]
        db_node["pass"] = params[:pass]
        db_node["dbname"] = params[:dbname]
        File.open("../../proj/script/config.xml", 'w') {|f| f.write(@xml.to_xml) }
        #redirect_to "config"
      end

      unless params[:addfeed].nil?
        feed_node = @xml.css("gtfs entry").last
        new_node = Nokogiri::XML::Node.new "entry", @xml
        new_node["agency"] = params[:agency]
        new_node["dirname"] = params[:dirname]
        new_node["url"] = params[:url]
        new_node["active"] = params[:active].nil? ? "0" : "1"
        feed_node.add_next_sibling(new_node)
        File.open("../../proj/script/config.xml", 'w') {|f| f.write(@xml.to_xml) }
        #redirect_to "config"
      end

      unless params[:savefeed].nil?
        feed_node = @xml.at_css("gtfs entry[dirname=\"#{params[:savefeed]}\"]")
        feed_node["agency"] = params[:agency]
        feed_node["dirname"] = params[:dirname]
        feed_node["url"] = params[:url]
        feed_node["active"] = params[:active].nil? ? "0" : "1"
        File.open("../../proj/script/config.xml", 'w') {|f| f.write(@xml.to_xml) }
        #redirect_to "config"
      end

      unless params[:delfeed].nil?
        @xml.at_css("gtfs entry[dirname=\"#{params[:delfeed]}\"]").remove
        File.open("../../proj/script/config.xml", 'w') {|f| f.write(@xml.to_xml) }
        #redirect_to "config"
      end

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

      @edit = params[:edit]
      @editfeed = params[:editfeed]
    else
      # show login screen
    end
    render :layout => "application"
  end
end