$(document).ready(function(){
  $("#collection_carousel").bind('slid', function(){
	  var carousel = $(this);
	  var index = $('.active', $(this)).index('#' + $(this).attr("id") + ' .item');
	  $(".iterator", $(this)).text(parseInt(index) + 1);
	});	
});
