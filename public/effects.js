var prepControls = function() {
	$('.controlbar-container').hide();
	$('.hisaishi-scaffold').hover(function() {
		$(this).find('.controlbar-container').slideToggle();
	});
};

var hideCursor = function() {
  var timer = 0, oldX = 0, oldY = 0;
  
  var startTimer = function() {
    timer = setTimeout(function(){
      $('body').css({cursor: 'none'});
    }, 10000);
  };
  
  $(document).mousemove(function(e) {
    newX = e.pageX;
    newY = e.pageY;
    if(newX != oldX || newY != oldY) {
      $('body').css({cursor: 'default'});
      clearTimeout(timer);
      startTimer();
    }
    oldX = newX;
    oldY = newY;
  })
}