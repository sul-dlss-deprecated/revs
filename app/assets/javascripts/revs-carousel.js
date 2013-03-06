$(document).ready(function(){
	// Carousel on Collection show page
  $("#collection_carousel").bind('slid', function(){
	  var carousel = $(this);
	  var druid= $('.carousel-inner', carousel).attr('druid');
	  var index = parseInt($('.active', carousel).attr('image-number'));
	  var rows = parseInt($('.carousel-inner', carousel).attr('rows'));
	  var start = parseInt($('.carousel-inner', carousel).attr('start'));
	  var end=parseInt(start)+parseInt(rows)
	  $(".iterator", carousel).text(index);
	  if (index == end - 2) {
		  $.getScript("/update_carousel?druid=" + druid + "&rows=" + rows + "&start=" + end)
		}
	});	
	
	// Carousel on home page
	$("#all_collections_carousel").bind('slid', function(){
		var active_item = $(".active", $(this));
		$("#featured-collection-nav #collection-title-link").text(active_item.attr("data-collection-title"));
		$("#featured-collection-nav #collection-title-link").attr('href',active_item.attr("data-collection-href"));
		$("#all_collections_carousel #collection-image-link").attr('href',active_item.attr("data-collection-href"));		
		$("#featured-collection-nav #collection-description").text(active_item.attr("data-collection-description"));
		$("#featured-collection-nav #collection-link").attr("href", active_item.attr("data-collection-href"));
	});
});
