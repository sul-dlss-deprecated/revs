$(document).ready(function(){
	// Carousel on Collection show page
  $("#collection_carousel").bind('slid', function(){
	  var carousel = $(this);
	  var druid= $('.carousel-inner', carousel).attr('druid');
	  var index = parseInt($('.active', carousel).attr('image-number'));
	  var rows = parseInt($('.carousel-inner', carousel).attr('rows'));
	  var start = parseInt($('.carousel-inner', carousel).attr('start'));
	  var total = parseInt($('.carousel-inner', carousel).attr('total'));
	  var end=parseInt(start)+parseInt(rows)
	  $(".iterator", carousel).text(index);
		if (index == 1) { $('#back-carousel-button').hide();}
			else
			{$('#back-carousel-button').show();}// enable back button unless we are on the first image
		if (index == total) { $('#forward-carousel-button').hide();}
			else
			{$('#forward-carousel-button').show();}// enable forward button unless we are on the last image
	  if (index == end - 2) { // fetch more items when we get close to the end of our set
		  $.getScript("/update_carousel?druid=" + druid + "&rows=" + rows + "&start=" + end)
		}
	});

  // Core jCarousel
  $('.jcarousel').jcarousel();

  $('.jcarousel-control-prev')
      .on('jcarouselcontrol:active', function() {
          $(this).removeClass('inactive');
      })
      .on('jcarouselcontrol:inactive', function() {
          $(this).addClass('inactive');
      })
      .jcarouselControl({
          target: '-=1'
      });

  $('.jcarousel-control-next')
      .on('jcarouselcontrol:active', function() {
          $(this).removeClass('inactive');
      })
      .on('jcarouselcontrol:inactive', function() {
          $(this).addClass('inactive');
      })
      .jcarouselControl({
          target: '+=1'
      });

  // Carousel on home page
  $('.jcarousel').on('jcarousel:targetin', 'li', function() {
    $("#featured-collection-nav #collection-title-link").text($(this).attr("data-collection-title"));
    $("#featured-collection-nav #collection-title-link").attr('href', $(this).attr("data-collection-href"));
    $("#featured-collection-nav #collection-image-link").attr('href', $(this).attr("data-collection-href"));
    $("#featured-collection-nav #collection-description").text($(this).attr("data-collection-description"));
    $("#featured-collection-nav #collection-link").attr('href', $(this).attr("data-collection-href"));
  });

});
