jQuery(function($) {
    // when the #agency field changes
    $("#map_agency_id").change(function() {
        // make a POST call and replace the content
        var agency = $('select#map_agency_id :selected').val();
        if(agency == "") agency="0";
        jQuery.get('/map/update_route_select/' + agency, function(data){
            $("#addressRoutes").html(data);
        })
        return false;
    });
})
