$(document).ready(function(){
	
	// Modal behavior for collection member show page.
	$("[data-modal-selector]").on('click', function(){
		$($(this).attr("data-modal-selector")).modal('show');
	  return false;
	});
		
});