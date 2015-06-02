$(document).ready(function(){

  // Initialize homepage carousel
  $('.homepage-carousel').jcarousel();

  // Initialize collection details carousel with autoscrolling at 3 second interval
  $('.collection_carousel').jcarousel()
      .hover(function() {
        $(this).jcarouselAutoscroll('stop');
      }, function() {
        $(this).jcarouselAutoscroll('start');
      })
      .jcarouselAutoscroll({
        interval: 3000,
        target: '+=1',
        autostart: true
      });

  // Initialize gallery carousel
  $('.saved-items-carousel').jcarousel({
        wrap: 'circular'
      })
      .hover(function() {
        $(this).jcarouselAutoscroll('stop');
      }, function() {
        $(this).jcarouselAutoscroll('start');
      })
      .jcarouselAutoscroll({
        interval: 5000,
        target: '+=1',
        autostart: true
      });

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
  // When new item slides into view, update metadata shown for item
  $('.homepage-carousel').on('jcarousel:targetin', 'li', function() {
    $("#featured-collection-nav #collection-title-link").text($(this).attr("data-collection-title"));
    $("#featured-collection-nav .archive-label").text($(this).attr("data-collection-archive"));
    $("#featured-collection-nav #collection-title-link").attr('href', $(this).attr("data-collection-href"));
    $("#featured-collection-nav #collection-image-link").attr('href', $(this).attr("data-collection-href"));
    $("#featured-collection-nav #collection-description").text($(this).attr("data-collection-description"));
    $("#featured-collection-nav #collection-link").attr('href', $(this).attr("data-collection-href"));
  });

  // Carousel on collection details page
  // When new item slides into view, update caption and variables used to get more items
  $('.collection_carousel').on('jcarousel:targetin', 'li', function() {
    var current_item = $(this);
    current_item.addClass('active');
    var druid = $('.collection_carousel').attr('data-druid');
    var index = parseInt(current_item.attr('data-image-number'));
    var rows = parseInt($('.collection_carousel').attr('rows'));
    var start = parseInt($('.collection_carousel').attr('start'));
    var total = parseInt($('.collection_carousel').attr('total'));
    var end = parseInt(start) + parseInt(rows);
    $(".iterator", '.jcarousel-wrapper').text(index);
    if (index == end - 2) { // fetch more items when we get close to the end of our set
      $.getScript("/update_carousel?druid=" + druid + "&rows=" + rows + "&start=" + end);
    }
    // Ensure jCarousel knows about remotely added items and makes next button active
    if ((index % 5) === 0) {
      $('.collection_carousel').jcarousel('reload');
    }
  });

  $('.collection_carousel').on('jcarousel:targetout', 'li', function() {
    $(this).removeClass('active');
  });

  // Carousel for saved items slideshow view
  $('.saved-items-carousel').on('jcarousel:targetin', 'li', function() {
    // When new item slides into view, update variables used to get more items
    var current_item = $(this);
    current_item.addClass('active');
    var index = parseInt(current_item.attr('data-image-number'));
    var start = parseInt($('.saved-items-carousel').attr('start'));
    var total = parseInt($('.saved-items-carousel').attr('total'));

    // Update "x of y" message
    $(".iterator", '.jcarousel-wrapper').text(index);

    // Update metadata for active item
    $(".saved-item-metadata .saved-item-title a").attr('href', $(this).attr("data-href"));
    $(".saved-item-metadata .saved-item-title a").text($(this).attr("data-title"));
    $(".saved-item-metadata .saved-item-year").text($(this).attr("data-year"));
    $(".saved-item-metadata .saved-item-location").text($(this).attr("data-location"));
    $(".saved-item-metadata .saved-item-description").text($(this).attr("data-description"));
    $(".saved-item-metadata .saved-item-annotation").text($(this).attr("data-annotation"));
  });

  $('.saved-items-carousel').on('jcarousel:targetout', 'li', function() {
    $(this).removeClass('active');
  });

});
