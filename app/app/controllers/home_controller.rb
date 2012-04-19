require "nokogiri"
require "mysql"

class HomeController < ActionController::Base
  def home
    render :layout => "application"
  end
end