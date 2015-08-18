$(document).ready(function(){

	$('.favorite_button').each(function(index, element){
		$(element).attr('href','#null');
	});
	$('.favorite_button').CreateBubblePopup({
		align: 'right',
		manageMouseEvents: 'false',
		innerHtmlStyle: {
			color:'#FFFFFF', 
			'text-align':'center'
		},
		themeName: 	'all-black',
		themePath: 	'/static/OwlHome/css/jquerybubblepopup-theme'
	 }); // Note: you need to use quotation marks for each CSS property of "innerHtmlStyle" with a "-"


	$('.favorite_button').click(function(){

		var button_id = this.id;
		button_id = button_id.split('.');
 
		var quote_id = button_id[0];
		var vote = button_id[1];
		var cache_key = button_id[2];
	
		var favorite_button = $(this);
		var bubble_popup_id = favorite_button.GetBubblePopupID(); //get the ID of the Bubble Popup associated to this shoppingcart button
		var seconds_to_wait = 3;

		var ld_id = '#' + quote_id + vote;
		if($(ld_id).text() == 'Add to Favorites') {
			vote = 'favorite';
		}
		else if($(ld_id).text() == 'Remove from Favorites') {
			vote = 'unfavorite';
		}

		$.get('/json/' + vote + '?quote_number=' + quote_id + '&cache_key=' + cache_key, function(data) {

		if(data.rate_successful) {
			
			var new_text;
			if(vote == 'favorite') {
				new_text = 'Remove from Favorites';
				$('.quote_wrapper' + quote_id).css("background-image", "url(/static/images/quote_bottom_yellow.png)");
                $('#' + quote_id + 'favmain').css("background", "transparent url(/static/images/favorite.png) 0 0 no-repeat");
                //53070.favorite.
			}
			else {
				new_text = 'Add to Favorites';
				$('.quote_wrapper' + quote_id).css("background-image", "url(/static/images/quote_bottom.jpg)");
                $('#' + quote_id + 'favmain').css("background", "transparent url(/static/images/favorite.png) 0 -18px no-repeat");
                
			}

			$(ld_id).hide("fast");
			$(ld_id).text(new_text);
			$(ld_id).show("fast");
		}

		// show a bubble popup with new options when "this" shoppingcart button is clicked
		favorite_button.ShowBubblePopup({

			align: 'left',
			position: 'right',
			manageMouseEvents: 'false',
			innerHtml: '<div><b>' + data.message_header + '</b> ' + data.message_body + '</div>', // + seconds_to_wait
											   
			innerHtmlStyle:{ 
				color:'#666666', 
				'text-align':'left'
			},
			themeName: 	'azure',
			themePath: 	'/static/OwlHome/css/jquerybubblepopup-theme'

		}, false); //save_options = false; it will use new options only on click event, it does not overwrite old options.

		});


		// "freeze" the Bubble Popup then it will not respond to mouse events (as mouseover/mouseout) 
		// until ".ShowBubblePopup()" or ".HideBubblePopup()" is called again.
		favorite_button.FreezeBubblePopup();

		// when the "close" link is clicked, hide the bubble popup
		$('#'+bubble_popup_id+' a:last').click(function(){
			$(favorite_button).HideBubblePopup();
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
					$(favorite_button).HideBubblePopup(); //hide the bubble popup associated to the shoppingcart button
				};
			},1000);
		};
		doCountdown();

	});//end onclick event

});
