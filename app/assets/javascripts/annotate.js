anno.addHandler('onAnnotationCreated', function(annotation) {
	jQuery.ajax({
		type: "POST",
		url: "/annotations",
		dataType: "JSON",
		data: "annotation="+JSON.stringify(annotation)+"&druid=" + jQuery("#druid").attr('data-druid'),
		success: function(data) {
	    annotation.id=data.id; // the annotation ID should match the database row ID
	  }
		});
		
		// these are added so the display to the user is correct for the new annotation; they will be set on the server when the page loads for all annotations
		annotation.username='me';
		annotation.updated_at='today';
});

anno.addHandler('onAnnotationUpdated', function(annotation) {
	jQuery.ajax({
	  type: "PUT",
		dataType: "JSON",
	  url: "/annotations/" + annotation.id,
	  data: "annotation="+JSON.stringify(annotation)
	});
});

// this gets called when the user clicks the delete icon
anno.addHandler('beforeAnnotationRemoved', function(annotation) {
	var r=confirm("Are you sure you want to delete this annotation?");
	if (r==false) {	return false;}
});

// this is what gets called when the annotation is actually deleted (assuming the user clicks OK to the confirmation dialog
anno.addHandler('onAnnotationRemoved', function(annotation) {
	jQuery.ajax({
	  type: "DELETE",
		dataType: "JSON",
	  url: "/annotations/" + annotation.id,
	});
});

annotorious.plugin.addUsernamePlugin = function(opt_config_options) { }

annotorious.plugin.addUsernamePlugin.prototype.onInitAnnotator = function(annotator) {
  // A Field can be an HTML string or a function(annotation) that returns a string
  annotator.popup.addField(function(annotation) { 
    return '<em>from ' + annotation.username + ' - '+ annotation.updated_at +'</em>'
  });
}

anno.addPlugin('addUsernamePlugin', {});	

function showAnnotations() {	
	togglePURLEmbed();
	toggleThumbImage();
	enableAnnotations();
	loadAnnotations();
}

function hideAnnotations() {
	togglePURLEmbed();
	toggleThumbImage();
}
	 
function enableAnnotations() {
	anno.makeAnnotatable(jQuery('#annotatable_image')[0]);	
}

function loadAnnotations() {
	jQuery.getJSON("/annotations/"+jQuery("#druid").attr('data-druid') + ".json",function(data) {
		for (var i = 0; i < data.length; i++) {
				annotation=JSON.parse(data[i].json)
        anno.addAnnotation(annotation);
			}
	});
}

function togglePURLEmbed() {
	jQuery('#image_workspace').toggleClass('hidden');	
}

function toggleThumbImage() {
	jQuery('#annotatable_workspace').toggleClass('hidden');	
}

function disableNewAnnotations() {
	try{anno.setSelectionEnabled(false);}	
	catch(err) {}
}

function toggleLinks() {
  $('.annotation_links').toggleClass('hidden-offscreen');
  $('#hide_annotations_link').toggleClass('hidden-offscreen');
}

$(document).ready(function(){
	
	$('#annotate_link').click(function() { 
		showAnnotations(); 
    toggleLinks();
		return false;
	 });
	
	$('#view_annotations_link').click(function() {
		 showAnnotations(); 
		 disableNewAnnotations(); 
     toggleLinks();
		 return false;
	 });

	$('#hide_annotations_link').click(function() {
		 hideAnnotations(); 
		 toggleLinks();
		 return false;
	 });
	
});
