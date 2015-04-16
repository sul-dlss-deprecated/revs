$(document).ready(function(){

	setup_links_that_disable();
  enable_autocomplete();

	// Modal behavior for collection member show page.
	$("[data-modal-selector]").on('click', function(){
		$($(this).attr("data-modal-selector")).modal('show');
	  return false;
	});

	setupItemDetailPanels();

  // Collapse Item Details flag details if JavaScript (open by default for no-JS browsers).
  $('#new_flag, #all_flags').hide();
  // Toggle details (new flag form and posted flags) when Flag action is selected.
  $('.flag-details').click(function(){
		// Added if/else conditions below during Bootstrap 3 upgrade because BS 3 prevents
		// JQuery from toggling the .hide and .show classes during animations as expected:
		// https://github.com/twbs/bootstrap/issues/9237
		// They might fix in Bootstrap 4; if so, it might be that
		// only the slideToggle line in 'else' is needed.
		if ($('#new_flag, #all_flags').hasClass('hide')) {
			$('#new_flag, #all_flags').removeClass('hide').hide().slideToggle('slow');
		} else {
			$('#new_flag, #all_flags').slideToggle('slow');
		}
    $('.flag-details').toggleClass('active');
		$('#flag_comment').focus();
    return false;
  });

  // Collapse Add to Gallery details if JavaScript (open by default for no-JS browsers).
  $('#add_to_gallery_form').hide();
  // Toggle details (new flag form and posted flags) when Flag action is selected.
  $('#add_to_gallery_link').on('click', function(){
    $('#add_to_gallery_form').slideToggle('fast');
    return false;
  });

  // Initialize Bootstrap tooltip
  $('.help').tooltip();

  // // admin users select all
  // $( '#admin-select-all-users' ).click( function () {
  //    $( 'input[type="checkbox"]' ).prop('checked', this.checked);
  //    }
  // );

  // saved_items select all
  $( '#saved_items-select-all' ).click( function () {
     $( 'input[type="checkbox"]' ).prop('checked', this.checked);
     toggle_highlight(this,$('.saved-item-row'));
     }
  );

    $( '.selected_items' ).change( function () {
      toggle_highlight(this,$('#saved_item_' + $(this).data('saved-item-id')));
    }
  );

  $(".autosubmit select").change(function() {
    ajax_loading_indicator($(this));
    $(this).closest('form').submit();
  });

   // Curator bulk update view controls and actions //
   // Called when 'Select all' checkbox is checked or unchecked.
   // Select all rows for edit when 'select all' checkbox is selected.
   $( '.curator-edit-options #select-all' ).click( function () {
      $( '.curator input[type="checkbox"]' ).prop('checked', this.checked);
      toggle_highlight(this,$('.result-item'));
      var field = $('#bulk_edit_attribute option:selected').text(); // current field selected in the select menu
      $('#documents.curator .result-item').each(function() { // loop through all result item rows
        updateEditStatus(field,'.result-item'); // update status message
      });

   });

     $( '.curator-edit-options #bulk_edit_action_update' ).click( function () {
       bulkEditShowUpdate();
       bulkEditHideReplace();
       bulkEditShowUpdateHeading();
    });
     $( '.curator-edit-options #bulk_edit_action_replace' ).click( function () {
       bulkEditShowUpdate();
       bulkEditHideReplace();
       bulkEditShowReplace();
       bulkEditShowUpdateHeading();
    });
     $( '.curator-edit-options #bulk_edit_action_remove' ).click( function () {
      bulkEditHideUpdate();
      bulkEditHideReplace();
      bulkEditHideUpdateHeading();
    });
   if ($( '#bulk_edit_action_update' ).is(':checked')) {
      bulkEditHideUpdate();
      bulkEditHideReplace();
      bulkEditShowUpdate();
      bulkEditShowUpdateHeading();
    }
    if ($( '#bulk_edit_action_remove' ).is(':checked')) {
      bulkEditHideUpdate();
      bulkEditHideReplace();
      bulkEditHideUpdateHeading();
    }
   if ($( '#bulk_edit_action_replace' ).is(':checked')) {
      bulkEditHideUpdate();
      bulkEditHideReplace();
      bulkEditShowUpdate();
      bulkEditShowReplace();
      bulkEditShowUpdateHeading();
    }

    function bulkEditShowReplace() {
      $('#bulk_edit_search_value' ).show();
      $('#bulk_edit_search_value').focus();
    }

    function bulkEditShowUpdate() {
      $( '#bulk_edit_new_value' ).show();
       $('#bulk_edit_new_value').focus();
    }

    function bulkEditShowUpdateHeading() {
      $('.update-field-value .update-field-heading').show();
      $('#bulk-update-button').removeClass('extra-padding');
    }

    function bulkEditHideReplace() {
      $( '#bulk_edit_search_value' ).hide();
      $( '#bulk_edit_search_value' ).val('');
    }

    function bulkEditHideUpdate() {
      $( '#bulk_edit_new_value' ).hide();
      $( '#bulk_edit_new_value' ).val('');
    }

    function bulkEditHideUpdateHeading() {
      $('.update-field-value .update-field-heading').hide();
      $('#bulk-update-button').addClass('extra-padding');
    }

   // Called when an individual checkbox is checked or unchecked in bulk edit view.
   // Update row status message if user changes individual checkbox
   $('.result-item-checkbox > input[type="checkbox"]').change(function() {
     var field = $('#bulk_edit_attribute option:selected').text(); // current value of select menu
     var row = $(this).closest('.result-item')
     toggle_highlight(this,row);
     updateEditStatus(field,"div[data-item-id='" + row.data('item-id') + "']"); // update status message
   });
   // Called when the 'Field to edit' select menu is changed.
   $('#bulk_edit_attribute').change(function() { // field changed in select menu
     updateBulkEditStatus();
   });
   // Called when the input field for the new field value loses focus.
   $('#bulk_edit_new_value').blur(function() { // input loses focus
     updateBulkEditStatus();
   });

   // Enter/leave curator edit mode
   $('#edit_mode_link').click(function() { // click the curator edit mode action link
    if (curatorEditMode() == 'false'){ // currently not in edit mode, click is to enter edit mode
			setCuratorEditMode(true);
    } else {
			setCuratorEditMode(false);
    }
		return false;
  });

   // visibility update link
   $('#visibility_link').click(function() { // click the curator update visibility link
    if (visibility() == 'hidden'){ // currently hidden; set to show
			setVisibility('visible');
    } else { // currently showing; set to hide
			setVisibility('hidden');
    }
		return false;
  });

	$(document).on('mouseleave','.annotation-info',function(){anno.highlightAnnotation();});
	$(document).on('mouseenter','.annotation-info',function(){
		annotation=($(this).data('json'));
		anno.highlightAnnotation(annotation);
	});

	$('#feedback_link').click(function() {
      $(".report-problem")[0].reset();
  		$("#subject").val('metadata');
		  $('#message').html('Suggest corrections for this item:');
		  $('#report-problem-form').slideToggle('slow');
		  return false;
		});

	$('#contact_us_link, .error-page-feedback').click(function() {
    $(".report-problem")[0].reset();
	  $('#report-problem-form').slideToggle('slow');
	  return false;
	});

	$('#report-problem-form .cancel-link').click(function() {
    $(".report-problem")[0].reset();
	  $('#report-problem-form').slideUp('fast');
	  return false;
	});

	// elements defined with the class "showOnLoad" and "hidden" classes will be hidden by default and then show when the page loads
	//  useful when you have non javascript friendly DOM elements you need to hide for no JS browsers so you can include a <noscript> tag with
	//   non JS versions
	showOnLoad();

});

// Determine which field has been selected in 'Field to edit' select menu and update status message for checked items with new field name.
function updateBulkEditStatus() {
  var field = $('#bulk_edit_attribute option:selected').text(); // current value of select menu
  $('#documents.curator .result-item').each(function() { // loop through all result item rows
    updateEditStatus(field,this); // update status message
  });
}

function druid() {
	return jQuery("#data-vars").attr('data-druid');
}

function visibility() {
	return jQuery("#data-vars").attr('data-visibility');
}

function curatorEditMode() {
	return jQuery("#data-vars").attr('data-curator-edit-mode');
}

function setCuratorEditMode(value) {
	$.ajax({
	        type: "POST",
	        url: "/curator/tasks/set_edit_mode/" + druid(),
					data: "value=" + value
	});
}

function setVisibility(value) {
	$.ajax({
	        type: "PUT",
	        url: "/curator/tasks/item/" +  druid() + "/set_visibility",
					data: "value=" + value
	});
}

$(document).on('blur',".user-login-email",function(){
	  var email=$(this).val();
	  var id=$(this).attr('id');
		if (email.indexOf('@stanford.edu') != -1) {
			$('#stanford-user-warning').removeClass('hidden'); // if the user is logging in or regisering with a stanford email address, warn them
			}
		else if (email != "" && id == "register-email") // if the user is on the registration form or edit form, do an ajax call to verify the email address is unique
		{
			$.ajax({
			        type: "POST",
			        url: "/check_email",
							data: "email=" + email
			});
		}
	}
);

$(document).on('blur',"#register-username",function(){
	  var username=$(this).val();
	  var id=$(this).attr('id');
		if (username != "") // do an ajax call to verify the username is unique
		{
			$.ajax({
			        type: "POST",
			        url: "/check_username",
							data: "username=" + username
			});
		}
	}
);

function showOnLoad() {
	$('.showOnLoad').removeClass('hidden hidden-offscreen');
	$('.showOnLoad').show();
}

function loadCollectionMembersGrid(id,page_type) {
  jQuery.ajax({type: "GET", dataType: "script", url: "/show_collection_members_grid/" + id + "?on_page=" + page_type});
}

function loadGalleryItemGrid(gallery_id) {
  jQuery.ajax({type: "GET", dataType: "script", url: "/galleries/members_grid/" + gallery_id});
}

function setupItemDetailPanels() {
  // Swap icon used in Item Details accordion when toggling metadata sections
  $('.accordion-body').collapse({
     toggle: false
   }).on('show',function (e) {
     $(e.target).parent().find(".icon-caret-right").removeClass("icon-caret-right").addClass("icon-caret-down");
   }).on('hide', function (e) {
     $(e.target).parent().find(".icon-caret-down").removeClass("icon-caret-down").addClass("icon-caret-right");
   });

   // Collapse Item Details metadata sections if JavaScript (open by default for no-JS browsers).
   $('.accordion-body').removeClass("in");

}

// For Curator Bulk Edit view - show or hide the field-to-be-updated status message depending on state of checkbox for that row item
// 'field' is currently selected field to edit in select menu; show this in status message
// 'context' is jQuery selector used to know which row to operate on
function updateEditStatus(field,context) {
  if ($(context).find(".result-item-checkbox > input[type='checkbox']").is(':checked')) { // row is selected for edit ..
		field_name=$('#bulk_edit_attribute option:selected').text();
    if (field_name != "") { // .. and a real field is selected in menu
      $(context).find('.edit-field-value > .current-value').text(field_name).show(); // indicate to user the row that will be updated ..
      $(context).find('.edit-field-value > .field-label').text("will be updated to:").show(); // .. and ..
      $(context).find('.edit-field-value > .new-value').text($('#bulk_edit_new_value').val()).show(); // .. the value that will be used for update
    } else { // row is selected but not field has been chosen in select menu ..
      $(context).find('.edit-field-value > .field-label').hide(); // .. so hide update message
      $(context).find('.edit-field-value > .current-value').hide();
      $(context).find('.edit-field-value > .new-value').hide();
    }
  } else { // row is not selected for edit ..
    $(context).find('.edit-field-value > .field-label').hide(); // .. so hide update message
    $(context).find('.edit-field-value > .current-value').hide();
    $(context).find('.edit-field-value > .new-value').hide();
  }
}

function split_mvf(val) {
  return val.split( /\|\s*/ );
}

function extractLast( term ) {
  return split_mvf(term).pop(); // multivalued delimiter goes here
}

// enable autocomplete suggestions for bulk editing for curators for enabled fields
function enable_autocomplete() {
      $( ".autocomplete" ).bind( "keydown", function( event ) {
          field=$(this).data('autocomplete-field');
          if ( event.keyCode === $.ui.keyCode.TAB &&
              $( this ).data( "ui-autocomplete" ).menu.active ) {
            event.preventDefault();
          }
        });

     $( "#bulk_edit_new_value").autocomplete({
          source: function( request, response ) {
            bulk_field=$('#bulk_edit_attribute :selected').data('autocomplete-field');
            if (bulk_field) {
              $.getJSON( "/autocomplete.json", {
                field: bulk_field,
                term: extractLast( request.term )
              }, response );
            }
          },
          minLength: 2,
          max: 10});

        $( ".autocomplete.mvf").autocomplete({
          source: function( request, response ) {
            $.getJSON( "/autocomplete.json", {
              field: field,
              term: extractLast( request.term )
            }, response );
          },
          search: function() {
            var term = extractLast( this.value );
            if ( term.length < 2 || term.length > 30) {
              return false;
            }
          },
          focus: function() {return false;},
          select: function( event, ui ) {
            var terms = split_mvf( this.value );
            terms.pop();
            terms.push( ui.item.value );
            terms.push( "" );
            this.value = terms.join( " | " ); // multivalued delimiter also goes here
            return false;
          }
        });

     $( ".autocomplete.single").autocomplete({
          source: function( request, response ) {
            $.getJSON( "/autocomplete.json", {
              field: field,
              term: extractLast( request.term )
            }, response );
          },
          minLength: 2,
          max: 10});
  }

// href links with the disable_after_click=true attribute will be automatically disabled after clicking to prevent double clicks
function setup_links_that_disable() {
	$("[show_loading_indicator='true']").each(function(){
    $(this).click(function(e){
	    ajax_loading_indicator($(this)); // show loading indicator in UI
	    });
    });
  $("[disable_after_click='true']").each(function(){
    $(this).click(function(e){
      e.preventDefault(); // stop default href behavior
      ajax_loading_indicator($(this)); // show loading indicator in UI
      url=$(this).attr("href"); // grab the URL
      $(this).attr("href","#"); // remove it so even if clicked again, nothing will happen!
      $(this).parent().addClass('disabled'); // disable the parent's element visually
      window.location.href=url; // go to the URL
      });
    });
}

function ajax_loading_indicator(element) {
  $("body").css("cursor", "progress");
	$('#loading-message').removeClass('hidden');
  if (element) {
      element.animate({opacity:0.25});
  		element.addClass("disabled");
  		if (element.attr("disable_with") != '') {
  			element.attr("enable_with",element.text()); // store the current text
  			element.text(element.attr("disable_with"));  // change the text
  			}
    }
}

function toggle_highlight(element,row) {
  (element.checked) ? row.addClass('highlighted') : row.removeClass('highlighted');
}

function ajax_loading_done(element) {
  $("body").css("cursor", "auto");
	$('#loading-message').addClass('hidden');
  if (!!element) {
    element.animate({opacity:1.0});
    element.removeAttr("disabled");
    element.removeClass("disabled");
		if (element.attr("enable_with") != '') { element.text(element.attr("enable_with"));} // change the text back
    }
}

// if the user clicks cancel on a confirm box, we need to hide the ajax loader
$(document).on('confirm:complete', function(e,answer) {
	element=$(e.target);
	if (answer == false && element.attr('show_loading_indicator') == 'true') {
 		ajax_loading_done(element);
 	}
});
