$(document).ready(function(){
	// Carousel on Collection show page
  $("#collection_carousel").bind('slid', function(){
	  var carousel = $(this);
	  var index = $('.active', carousel).index('#' + carousel.attr("id") + ' .item');
	  $(".iterator", carousel).text(parseInt(index) + 1);
	});	
	
	// Carousel on home page
	$("#all_collections_carousel").bind('slid', function(){
		var active_item = $(".active", $(this));
		$(".featured-description #collection-title").text(active_item.attr("data-collection-title"));
		$(".featured-description #collection-description").text(active_item.attr("data-collection-description"));
		$(".featured-description #collection-link").attr("href", active_item.attr("data-collection-href"));
	});
});
