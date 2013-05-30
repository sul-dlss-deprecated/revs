var tooltip;

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
     $(e.target).parent().find(".icon-chevron-right").removeClass("icon-chevron-right").addClass("icon-chevron-down");
   }).on('hide', function (e) {
     $(e.target).parent().find(".icon-chevron-down").removeClass("icon-chevron-down").addClass("icon-chevron-right");
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
		else if (email != "" && id == "register-email") // if the user is on the registration form, do an ajax call to verify the email address is unique
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
	$('.showOnLoad').removeClass('hidden');	
	$('.showOnLoad').show();
}