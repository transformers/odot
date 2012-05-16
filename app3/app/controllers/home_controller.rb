class HomeController < ApplicationController
  def home
    @agencies = Agency.find_by_sql("select * from agency")
    @routes = Agency.find_by_sql("select * from routes")
  end
end