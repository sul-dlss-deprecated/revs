$(document).ready(function(){
	  
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
    $('#new_flag, #all_flags').slideToggle('slow');
    $('.flag-details').toggleClass('active');
    return false;
  });
  
 

   // Curator bulk update view controls and actions //
   // Put focus on new value input box on page load
   $('#bulk_edit_new_value').focus();
   // Called when 'Select all' checkbox is checked or unchecked.
   // Select all rows for edit when 'select all' checkbox is selected.
   $( '.curator-edit-options #select-all' ).click( function () {
      $( '.curator input[type="checkbox"]' ).prop('checked', this.checked);
      if ($('#bulk_edit_attribute option:selected').text() != "Field to update...") { // don't do anything else if no real field is selected in menu
        var field = $('#bulk_edit_attribute option:selected').text(); // current field selected in the select menu
        $('#documents.curator .result-item').each(function() { // loop through all result item rows
          updateEditStatus(field,'.result-item'); // update status message
        });
      }
   });
   // Called when an individual checkbox is checked or unchecked.
   // Update row status message if user changes individual checkbox
   $('.result-item-checkbox > input[type="checkbox"]').change(function() {
     var field = $('#bulk_edit_attribute option:selected').text(); // current value of select menu
     var context = $(this).closest('.result-item').data('item-id');
     updateEditStatus(field,"div[data-item-id='" + context + "']"); // update status message
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
		  var link=jQuery('#edit-mode-text');
      link.text(link.attr('data-leave-mode-text'));
      $('.edit-mode-status').removeClass("hidden-offscreen");
			setCuratorEditMode(true);
    } else {
		  var link=jQuery('#edit-mode-text');
      link.text(link.attr('data-enter-mode-text'));
      $('.edit-mode-status').addClass("hidden-offscreen");
			setCuratorEditMode(false);
    }
		return false;
  });

	$(document).on('mouseleave','.annotation-info',function(){anno.highlightAnnotation();});
	$(document).on('mouseenter','.annotation-info',function(){
		annotation=($(this).data('json'));
		anno.highlightAnnotation(annotation);
	});

	$('#contact_us_link').click(function() {
	  $('#report-problem-form').slideToggle('slow');
	  return false;
	});

	$('#report-problem-form .cancel-link').click(function() {
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

function curatorEditMode() {
	return jQuery("#data-vars").attr('data-curator-edit-mode');	
}

function setCuratorEditMode(value) {
	jQuery("#data-vars").attr('data-curator-edit-mode',value);	
	$.ajax({
	        type: "POST",
	        url: "/curator/tasks/set_edit_mode/" + druid(),
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

function loadCollectionMembersGrid(id) {
  jQuery.ajax({type: "GET", dataType: "script", url: "/show_collection_members_grid/" + id});
}

function setupItemDetailPanels() {
  // Swap icon used in Item Details accordion when toggling metadata sections
  $('#item-details-accordion').collapse({
     toggle: false
   }).on('show',function (e) {
     $(e.target).parent().find(".icon-caret-right").removeClass("icon-caret-right").addClass("icon-caret-down");
   }).on('hide', function (e) {
     $(e.target).parent().find(".icon-caret-down").removeClass("icon-caret-down").addClass("icon-caret-right");
   });

   // Collapse Item Details metadata sections if JavaScript (open by default for no-JS browsers).
   $('#item-details-accordion .accordion-body').removeClass("in");
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
