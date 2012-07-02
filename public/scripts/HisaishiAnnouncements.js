var HisaishiAnnouncement = function(params) {
	
	var settings = {
		id: null,
		text: null,
		displayed: true,
		ann_order: null,
		container: null,
		
		next: function(id){}
	};
	
	$.extend(settings, params);
	
	var state = {
		elem: null,
	};
	
	var priv = {},
	pub = {};
	
	pub.play = function() {
	  if (!settings.displayed) {
	    var w = $(window).width();
	    var l = 5000 + (200 * settings.text.length);
	    var elem = $('<span />', {
	      text: settings.text
	    });
	    elem.css({
	      position: 'absolute',
	      top: '0',
	      left: w + 'px'
	    });
	    $(settings.container).append(elem);
	    elem.animate({
	      left: (-1 * elem.width()) + 'px'
	    }, l, function(){
	      settings.displayed = true;
	      $(this).remove();
	      settings.next(settings.id);
	    });
	  }
	};
	
	pub.displayed = function() {
	  return settings.displayed;
	};
	
	pub.init = function() {
	};
	
	pub.init();
	
	return pub;
	
};

var HisaishiAnnouncements = function(params) {
	
	var settings = {
		containers: {
			announcements: null
		},
		source: null,
		socket_url: null
	};
	
	var state = {
		queue: [],
		
		track: null,
		playstate: null,
		
		socket: null,
		
		countdowns: {
			next: null
		}
	};
	
	var priv = {};
	
	var pub = {};
	
	priv.scaffold = function(ident) {
	};
	
	priv.scaffoldQueue = function(queueIdent, trackIdent) {
	};
	
	priv.queueStat = function(a_id, state) {
		$.post('/announce-info-update', {
			_csrf: csrf,
			announce_id: a_id,
			state: state
		});
	};
	
	priv.nextHS = function() {
	};
	
	priv.switchHS = function(id, play) {
	};
	
	priv.setup = function() {
	};
	
	$.extend(settings, params);
	
	priv.parseQueue = function() {
		priv.setup();
	};
	
	priv.getNext = function() {
	  var next = null;
	  for (var i = 0; i < state.queue.length; i++) {
	    if (!state.queue[i].displayed()) {
	      next = i;
	      break;
	    }
	  }
	  return next;
	};
	
	priv.playNext = function() {
	  var next = priv.getNext();
	  if (next !== null) {
	    state.queue[next].play();
	  }
	};
	
	priv.importData = function(data) {
		for (var i in data) {
			if (data.hasOwnProperty(i)) {
				if (!state.queue[i]) {
					state.queue[i] = new HisaishiAnnouncement({
					  id: data[i].id,
					  text: data[i].text,
					  displayed: data[i].displayed,
					  ann_order: data[i].ann_order,
					  container: settings.containers.announcements,
					  
					  next: function(id) {
					    priv.queueStat(id, "displayed");
					    priv.playNext();
					  }
					});
				}
			}
		}
		priv.playNext();
	};
	
	priv.fetchSource = function() {
		$.getJSON(settings.source, {}, priv.importData);
	};
	
	pub.init = function() {
		if (!!settings.socket) {
			state.socket = $.websocket(settings.socket, {
				open: function() {
				},
		        close: function() {
		        },
		        events: {
		        	x: function(e) {
		        		// e.data.foo
		        	},
		        	
		        	hi: function(e) {
		        		console.log('hello :3');
		        	},
		        	bye: function(e) {
		        		console.log('see you later :3');
		        	},
		        	
		        	announcements: function(e) {
		        		console.log("new data");
		        		priv.fetchSource();
		        	}
		        }
			});
		}
		
		if (!!settings.source) {
			priv.fetchSource();
		}
	};
	
	pub.init();
	
	return pub;
};
