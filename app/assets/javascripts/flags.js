$(document).ready(function() {

  $('select#state_selection').change(function() { 
  	jQuery.ajax({type: "GET", dataType: "script", url: "/flags/update_flag_table", data: "selection=" + $('select#state_selection').val() + "&username=" + $('#profile_username').val()});
  });

});
