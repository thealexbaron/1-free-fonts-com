    $(document).ready(function() {
        $('.comment_button').click(function() {
                var this_item = $(this).parents('form');
                var this_document_wrapper = $(this).parents('.document_wrapper');
                var dataString = $(this).parents('form').serialize();
                clear_all();
                $.ajax({
                    type: 'POST',
                    url: "/user/comment",
                    data: dataString,
                    success: function (data, textStatus, jqXHR) {
                        if (data.error.redirect == 'no') {
                            $('.unique_comment_unit').clone().appendTo(this_document_wrapper.find('.new_comments')).removeClass('unique_comment_unit').addClass('comment_unit new_comment');

                            this_document_wrapper.find('.new_comment').find('.comment_user_name').html(window.c_user_uid);
                            this_document_wrapper.find('.new_comment').find('.comment_date').html(data.comment.ts);
                            this_document_wrapper.find('.new_comment').find('.comment_text').html(data.comment.comment);
                            this_document_wrapper.find('.new_comment').find('.comment_image').html('<img src="/static/images/users/' + window.c_user_id + '-small.jpg" />');
                            
                            this_document_wrapper.find('.comment_box').attr('disabled', 'disabled');
                        }
                        else {
                            processJson(data, textStatus, jqXHR, this_item);
                        }
                    }
                });
            });

            $('.show_comments').click(function() {
                var document_block = $(this).parents('.document_block');
                document_block.find('.existing_comments').slideDown('slow', function() {
                    document_block.find('.show_comments').hide('slow');
                });
            });
        });
