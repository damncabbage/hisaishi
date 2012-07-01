var HisaishiAnnouncement = function(params) {
	
	var settings = {
		id: null,
		text: null,
		displayed: true,
		ann_order: null,
		container: null
	};
	
	$.extend(settings, params);
	
	var state = {
		elem: null,
	};
	
	var priv = {},
	pub = {};
	
	pub.play = function() {
	  if (!settings.displayed) {
	    var elem = $('<span />', {
	      text: settings.text
	    });
	    elem.css({
	      position: 'absolute',
	      top: '0',
	      left: '100%'
	    });
	    $(settings.container).append(elem);
	    elem.animate({
	      left: (-1 * elem.width()) + 'px'
	    }, 2000, function(){
	      settings.displayed = true;
	      $(this).remove();
	    });
	  }
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
	
	priv.queueStat = function(q_id, state) {
		$.post('/announcements-info-update', {
			_csrf: csrf,
			queue_id: q_id,
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
	
	priv.importData = function(data) {
		for (var i in data) {
			if (data.hasOwnProperty(i)) {
				if (!state.queue[i]) {
					state.queue[i] = new HisaishiAnnouncement({
					  id: data[i].id,
					  text: data[i].text,
					  displayed: data[i].displayed,
					  ann_order: data[i].ann_order,
					  container: settings.containers.announcements
					});
					state.queue[i].play();
				}
			}
		}
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
