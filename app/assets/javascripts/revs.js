var tooltip;

$(document).ready(function(){
	  
	// Modal behavior for collection member show page.
	$("[data-modal-selector]").on('click', function(){
		$($(this).attr("data-modal-selector")).modal('show');
	  return false;
	});
	
	// elements defined with the class "showOnLoad" and "hidden" classes will be hidden by default and then show when the page loads
	//  useful when you have non javascript friendly DOM elements you need to hide for no JS browsers so you can include a <noscript> tag with
	//   non JS versions
	showOnLoad();

		
});

$(document).on('blur',".user-login-email",function(){
	  var email=$(this).val();
		if (email.indexOf('@stanford.edu') != -1) {
			window.alert('Stanford users should not use the sign in or sign up pages!  If you are webauthed via SunetID, you already have an account. If you are not webauthed, please do that first. Do not enter your SUNET password here!');
			}
		}
);
	
function showOnLoad() {
	$('.showOnLoad').removeClass('hidden');	
	$('.showOnLoad').show();
}