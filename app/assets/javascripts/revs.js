$(document).ready(function(){
	  
	// Modal behavior for collection member show page.
	$("[data-modal-selector]").on('click', function(){
		$($(this).attr("data-modal-selector")).modal('show');
	  return false;
	});

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

   // Collapse Item Details flag details if JavaScript (open by default for no-JS browsers).
   $('#new_flag, #all_flags').hide();
   // Toggle details (new flag form and posted flags) when Flag action is selected.
   $('.flag-details').click(function(){
     $('#new_flag, #all_flags').toggle();
     $('.flag-details').toggleClass('active');
     return false;
   });

	// elements defined with the class "showOnLoad" and "hidden" classes will be hidden by default and then show when the page loads
	//  useful when you have non javascript friendly DOM elements you need to hide for no JS browsers so you can include a <noscript> tag with
	//   non JS versions
	showOnLoad();


});

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
