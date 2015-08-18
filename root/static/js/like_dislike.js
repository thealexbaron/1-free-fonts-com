$(document).ready(function(){

	$('.like_dislike_button').each(function(index, element){
		$(element).attr('href','#null');
	});

	$('.like_dislike_button').CreateBubblePopup({
		align: 'right',
		manageMouseEvents: 'false',											
	    innerHtml: '', 
		innerHtmlStyle: {
		    color:'#FFFFFF', 
		    'text-align':'center'
		},											
	    themeName: 	'all-black',
		themePath: 	'/static/css/jquerybubblepopup-theme'
    });
	// Note: you need to use quotation marks for each CSS property of "innerHtmlStyle" with a "-"


	// when shoppingcart button is clicked then new bubble popup is shown with new options;
	// finally, if the bubble popup is not closed, pause for 10 seconds then hide it...

	$('.like_dislike_button').click(function(){

		var button_id = this.id;
		button_id = button_id.split('.');
 
		var document_id = button_id[0];
		var vote = button_id[1];
	
		var like_dislike_button = $(this);
		var bubble_popup_id = like_dislike_button.GetBubblePopupID(); //get the ID of the Bubble Popup
		var seconds_to_wait = 3;

		$.get('/json/like_dislike?document_id=' + document_id + '&vote=' + vote, function(data) {

		    if(data.rate_successful) {
    			var ld_id = '#' + document_id + vote;

    			var original_votes = $(ld_id).html();
    			original_votes = parseFloat(original_votes);

	    		var new_vote_count = original_votes + 1;

    			$(ld_id).hide("fast");
    			$(ld_id).text(new_vote_count);
	    		$(ld_id).show("fast");
			
		    }

    		// show a bubble popup with new options when "this" shoppingcart button is clicked
	    	like_dislike_button.ShowBubblePopup({
		    	align: 'left',
			    position: 'right',
    		    manageMouseEvents: 'false',
	    		innerHtml: '<div><b>' + data.message_header + '</b> ' + data.message_body + '</div>', // + seconds_to_wait
		    	innerHtmlStyle:{ 
			    color:'#666666', 
    				'text-align':'left'
	    		},
		    	themeName: 	'azure',
			    themePath: 	'/static/css/jquerybubblepopup-theme'
            }, false); //save_options = false; it will use new options only on click event, it does not overwrite old options.

					
        });


		// "freeze" the Bubble Popup then it will not respond to mouse events (as mouseover/mouseout) 
		// until ".ShowBubblePopup()" or ".HideBubblePopup()" is called again.
		like_dislike_button.FreezeBubblePopup();

		// when the "close" link is clicked, hide the bubble popup
		$('#'+bubble_popup_id+' a:last').click(function(){
			$(like_dislike_button).HideBubblePopup();
		});

		//start the countdown then hide the bubble popup
		function doCountdown(){
			var timer = setTimeout(function(){
				seconds_to_wait--;
				if($('#'+bubble_popup_id+' span.countdown').length>0){ //if exists... 
					$('#'+bubble_popup_id+' span.countdown').html(seconds_to_wait);
				};
				if(seconds_to_wait > 0){
					doCountdown();
				}else{
					$(like_dislike_button).HideBubblePopup(); //hide the bubble popup associated to the shoppingcart button
				};
			},1000);
		};
		doCountdown();

	});//end onclick event

});
