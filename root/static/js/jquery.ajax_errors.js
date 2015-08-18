function processJson(data, textStatus, jqXHR, this_item) {

    $('.loading_animation').hide();

    if(data.error.none === 1) {

        if(data.error.redirect == 'reload') {
            window.location.reload();
        }
        else if (data.error.redirect == 'no') {

        }
        else {
            window.location = data.error.redirect;
        }
    }
    else {
        for(var i in data) {
            var data_set = data[i];

            for(var j in data_set) {

                var error_div_class_name = "."+j+"_error";
                var div_class_name = "."+j;

                var regular_div;
                var error_div;
                if (this_item == undefined) {
                    regular_div = $(div_class_name);
                    error_div = $(error_div_class_name);
                }
                else {
                    regular_div = $(this_item).children(div_class_name);
                    error_div = $(this_item).children(error_div_class_name);
                }
                
                regular_div.addClass("error_box");
                error_div.addClass("error_text");

                var errors = data_set[j];
                error_div.html("");
                error_div.hide();
                for(var i in errors) {

                    error_div.append(errors[i] + "<br />");

                }
                error_div.slideDown('slow');
            }
        }

        return false;
    }
}
