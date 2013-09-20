$(document).ready(function() {

$('select#state_selection').change(function() { //change the sort for the flag table
	jQuery.ajax({type: "GET", dataType: "script", url: "/flags/update_flag_table/"+$('select#state_selection').val()})
});
});
