$(document).ready(function(){
	$(".image-stitch").each(function(){
	  var canvas = document.getElementById($(this).attr("id"));
	  var context = canvas.getContext('2d');
	  var image_urls = $(this).attr("data-image-urls").split(", ");
		stitch_images(image_urls.slice(0, 13), function(images){
			var i=0;
			for(var image in images) {
				var w = (i%4) * 100;
				var h = 0;
				// There has to be a better way to determine the height of each row.
				// Ultimately we should be checking the height and
				// width of each image to determine the xy coordinates.
				if(i >= 8) {
					var h = 200;
				} else if(i >= 4) {
					var h = 100;
				}
				context.drawImage(images[image], w, h)
				i++;
			}
		});
	});
});


function stitch_images(image_urls, callback) {
  var images = {};
  var loaded_images = 0;
  var num_images = image_urls.length;
  for(var src in image_urls) {
    images[src] = new Image();
    images[src].onload = function() {
      if(++loaded_images >= num_images) {
        callback(images);
      }
    };
    images[src].src = image_urls[src];
  }
}