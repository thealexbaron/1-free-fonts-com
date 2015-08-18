$(document).ready(function () {

    $('.search_button').click(function() {
        $('.search_form').submit();
    });

	$('.search_form').submit(function() {
        var target = $(this).attr("id");
        var search_input = $("#" + target + " .search_box").val();

        if(search_input == "" || search_input == "search fonts..." || search_input == "search users' fonts...") {
            return false;
        }
        else {
            var search_type = $(".search_type").val();
            var base = $(this).attr("action");
            var search_url = $(this).serialize();
            var seo_url = search_url.replace(/[&=]/g, "/");

            seo_url = seo_url.replace(/[,-.]/g, "+");
            seo_url = seo_url.replace(/[!]/g, "");

            var full_seo_url = (base + "/" + seo_url);
            window.location = ("/" + full_seo_url);
            return false;
        }
    });

	check_and_change_drop_down();

	$('.search_type').change(function() {
		check_and_change_drop_down();
	});

	function check_and_change_drop_down() {
		var search_type = $(".search_type").val();
		remove_autocomplete();
		if(search_type == "author") {
			$('.search_action').attr('value', 'search_authors');
			$('.search_box').attr('name', 'search_authors');

			add_autocomplete("search_box","author","complete_name");

		}
		else if (search_type == "font") {
			$('.search_box').attr('name', 'keyword');
		}
		else if (search_type == "category") {

			$('.search_box').attr('name', 'category');
			$('.search_action').attr('value', '');
			$('.search_action').attr('name', '');
			
			add_autocomplete("search_box","category","category");
		}
	}

	function remove_autocomplete() {
		$( ".search_box" ).autocomplete( "destroy" );
		$('.search_action').attr('value', 'search');
		$('.search_action').attr('name', 'action');
	}

	function add_autocomplete (form_id,type,json_identifier) {
        $("." + form_id).autocomplete({
            minLength: 2,
            //define callback to format results
            source: function(req, add){
                req['limit'] = 15;
                req['type'] = type;
                req['action'] = 'auto_complete';

                $.getJSON("/json/autocomplete?callback=?", req, function(data) {
                    var suggestions = [];
                    $.each(data, function(i, val) {
                        suggestions.push(val[json_identifier]);
                    });
                    //pass array to callback
                    add(suggestions);
                });
            }

        });
	}

	$('.clearme').one("focus", function() {
		$(this).val("");
		$(this).removeClass("no_focus_input").addClass("in_focus_input");

	});
});
