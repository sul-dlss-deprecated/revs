$(document).ready(function(){
  // Called when an admin user checks the collection highlight checkbox
  $('.collection-highlight-checkbox').change(function() {
    var collection_id = $(this).data('id');
    var checked = $(this).prop('checked');
		$.ajax({
		        type: "POST",
		        url: "/admin/collection_highlights/set_highlight/" + collection_id,
						data: "highlighted=" + checked
		});
  });
});