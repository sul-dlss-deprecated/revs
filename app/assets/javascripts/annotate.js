anno.addHandler('onAnnotationCreated', function(annotation) {
	jQuery.ajax({
		type: "POST",
		url: "/annotations",
		data: "annotation="+JSON.stringify(annotation)+"&annotation_text="+annotation.text+"&druid=" + jQuery("#annotate_link").attr('data-druid')
		});
});

function annotateImage() {	
	anno.makeAnnotatable(jQuery('.pe-img-canvas')[0]);	
}