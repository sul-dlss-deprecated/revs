$(document).ready(function() {

$('select#state_selection').change(function() { 
	jQuery.ajax({type: "GET", dataType: "script", url: "/flags/update_flag_table/"+$('select#state_selection').val()})
});

$('select#curator_flag_selection').change(function() { 
	jQuery.ajax({type: "GET", dataType: "script", url: "/flags/update_curator_flag_table/"+$('select#curator_flag_selection').val()})
});


});
