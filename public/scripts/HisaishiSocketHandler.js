var HisaishiSocketHandler = function(path, autoStart) {
  var sock = null;
  var events = {};
  var _path = path;
  var _autoStart = (!!autoStart) ? autoStart : true;
  
  var initSocket = function() {
    sock = $.websocket(_path, {
      open: function() {
        console.log("Socket: Connected");
      },
      close: function() {
        console.log("Socket: Disconnected");
      },
      events: events
		});
  };
  
  var pub = {};
  
  pub.addEvents = function(newEvents) {
    for (var i in newEvents) {
      events[i] = newEvents[i];
    }
    pub.init();
  };
  
  pub.init = function() {
    if (_autoStart) {
      initSocket();
    }
  };
  
  pub.init();
  
  return pub;
};

