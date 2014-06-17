$(document).ready(function() {

  $('select#state_selection').change(function() { 
  	jQuery.ajax({type: "GET", dataType: "script", url: "/flags/update_flag_table", data: "selection=" + $('select#state_selection').val() + "&username=" + $('#profile_username').val()});
  });

  $('select#curator_flag_selection').change(function() { 
  	jQuery.ajax({type: "GET", dataType: "script", url: "/flags/update_curator_flag_table",data:"selection="+$('select#curator_flag_selection').val()});
  });

  $('div#refresh_flags').click(function() { 
  	jQuery.ajax({type: "GET", dataType: "script", url: "/flags/update_curator_flag_table",data:"selection="+$('select#curator_flag_selection').val()});
  });


});
