var intervalId;

$(function() {
	var $m = $('#myModal');

	$('.pre_download').click(function () {
		doTimer(3); // seconds
		var id = $(this).attr('data-id');
		$m.find('.start_download').attr('disabled', 'disabled');
		results.forEach(function(result) {
			if (result.id === id) {
				$m.find('.start_download').attr('href', result.url);
				$m.find('.modal-header h3').html('Download ' + result.name);
			}
		});
	});

	$('.start_download').click(function () {
		if ($(this).attr('disabled')) {
			return false;
		}
		$m.modal('hide');
	});

	$('a').click(function() {
		if ($(this).attr('disabled')) {
			return false;
		}
	});

	$m.on('hidden.bs.modal', function () {
		clearInterval(intervalId);
	})


	function doTimer(countDown) {
		$m.find('.start_download').html('Start Download in ' + countDown);
		intervalId = setInterval(function() {
			if (countDown === 0) {
				clearInterval(intervalId);
				$m.find('.start_download').removeAttr('disabled');
				$m.find('.start_download').html('Start Download');
			}
			else {
				$m.find('.start_download').html('Start Download in ' + countDown);
				countDown--;
			}
		}, 1000);
	}

});
