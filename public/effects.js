var hiding = 'unset';

var prepControls = function() {
	setTimeout(function() {
	  if(hiding == 'unset') {
	    $('.controlbar-container').slideToggle();
	    hiding = 'enabled';
    }
	}, 5000);

  var toggleControls = function() {
    if(hiding == 'enabled') {
    	$('.controlbar-container').slideToggle();
  	}
  };

	$('.hisaishi-scaffold').hover(toggleControls);
};

var hideCursor = function() {
  var timer = 0, oldX = 0, oldY = 0;
  
  var startTimer = function() {
    timer = setTimeout(function(){
      $('body').css({cursor: 'none'});
    }, 1000);
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
  });
};