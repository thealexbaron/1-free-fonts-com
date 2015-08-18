$(document).ready(function(){

    $("#login_dialog").dialog({
		//show: "blind",
		modal: true,
		autoOpen: false,
		close: function() {
			$("#login_dialog").html("");
		}
	});						

$(".signup_button").click(function(){

$.ajax({
  url: "/signup",
  success: function(data){
    $("#login_dialog").html(data);
	$("#login_dialog").dialog( "option", "title", 'Sign Up' );
	$("#login_dialog").dialog( "option", "width", 385 );
	$("#login_dialog").dialog('open');
  }
    
});

});

$(".login_button").click(function(){

	var after_login = $(this).attr("title");

$.ajax({
  url: "/login",
  type: "POST",
  data: "after_login=" + after_login,
  success: function(data){
	$("#login_dialog").html(data);
	$("#login_dialog").dialog( "option", "title", 'Login' );
	$("#login_dialog").dialog( "option", "width", 285 );
	$("#login_dialog").dialog('open');
  }
    
  });

});

});
