class HomeController < ApplicationController
  def home
    @agencies = Agency.find_by_sql("SELECT agency_id,
CASE WHEN LENGTH(TRIM(agency_name))>35 THEN CONCAT(LEFT(TRIM(agency_name), 33),'...') ELSE TRIM(agency_name) END 'agency_name' FROM agency")

    @routes = Agency.find_by_sql("SELECT route_id, agency_id, route_short_name,
CASE WHEN LENGTH(TRIM(route_long_name))>35 THEN CONCAT(LEFT(TRIM(route_long_name), 33),'...') ELSE TRIM(route_long_name) END 'route_long_name' FROM routes")
  end
end
