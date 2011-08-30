var prepControls = function() {
	$('.controlbar-container').hide();
	$('.hisaishi-scaffold').hover(function() {
		$(this).find('.controlbar-container').slideToggle();
	});
};