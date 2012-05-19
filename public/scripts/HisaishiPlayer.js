/* Hisaishi List */

if (!HisaishiEngine) {
	throw {
		type: 'NoHisaishiEngineException',
		message: 'No Hisaishi engine script found.'
	};
}

var HisaishiPlayer = function(params) {
	
	var settings = {
		hsParams: {},
		containers: {},
		source: null,
		socket_url: null,
		playing: null
	};
	
	var state = {
		tracks: {},
		queue: [],
		
		current_queue: null,
		track: null,
		playstate: null,
		
		socket: null,
		
		hs: {},
		hr: {}
	};
	
	var priv = {};
	
	var pub = {};
	
	priv.scaffold = function(ident) {
		var track = state.tracks[ident];
		
		var display = $('<div />', {
			id: 'scaffold-' + ident,
			'class': 'hisaishi-scaffold'
		}),
		cover = (track.compiledCover == '') ? '' : $('<img />', {
			id: 'track-image-' + ident,
			src: track.compiledCover,
			'class': 'track-image'
		}),
		lyrics = $('<div />', {
			id: 'lyrics-container-' + ident,
			'class': 'lyrics-container'
		}),
		audio = $('<div />', {
			id: 'audio-container-' + ident,
			'class': 'audio-container'
		}),
		controlbar = $('<div />', {
			id: 'controlbar-container-' + ident,
			'class': 'controlbar-container'
		}),
		controls = $('<div />', {
			id: 'controls-container-' + ident,
			'class': 'controls-container'
		}),
		queue = $('<div />', {
			id: 'queue-container-' + ident,
			'class': 'queue-container'
		});
		controlbar
		  .append(controls);
		
		display
			.append(cover)
			.append(lyrics)
			.append(audio)
			.append(controlbar);
		
		if (settings.containers.display) {
			$(settings.containers.display).append(display);
		}
	};
	
	priv.scaffoldQueue = function(ident) {
		var fields = ['title', 'artist', 'album', 'karaoke'],
		listitem = $('<li />', {
			id:   'select-track-' + ident
		});
		
		for (var i in fields) {
			if (fields.hasOwnProperty(i) && i != 'length') {
		    if (fields[i] == 'karaoke') {
		      var karaoke_setting = 'Warning: Karaoke setting not set';
		      if (track[fields[i]] == 'true') karaoke_setting = 'Karaoke version';
		      else if (track[fields[i]] == 'false') karaoke_setting = 'Vocal version';
		      
			    var part = $('<div />', {
				    text: karaoke_setting, 
				    'class': 	'track-' + fields[i]
			    });
	      } else {
			    var part = $('<div />', {
				    text: track[fields[i]], 
				    'class': 	'track-' + fields[i]
			    });
		    }
				listitem.append(part);
			}
		}
		
		var that = this;
		listitem.click(function(){
			that.switchHS(this.id.replace('select-track-', ''));
		});
		
		if (settings.containers.list) {
			$(settings.containers.list).append(listitem);
		}
	};
	
	priv.nextHS = function() {
		// switch HS to next song
		// pop warning
		// wait for 30 seconds
	};
	
	priv.switchHS = function(id, play) {
		state.hs[state.track].stopSong();
		state.track = id;
		this.setup();
		
		if (!!play) {
			state.hs[state.track].playSong();
		}
	};
	
	priv.setup = function() {
		var currentTrack = state.track;
		$('.hisaishi-scaffold').not('#scaffold-' + currentTrack).hide();
		if (!state.hs[currentTrack]) {
			var track = state.tracks[currentTrack];
			
			var hsParams = {
				src: {
					lyrics: track.compiledLyrics,
					audio: 	track.compiledAudio
				},
				containers: {
					lyrics:		'#lyrics-container-' 	+ currentTrack,
					audio:		'#audio-container-' 	+ currentTrack,
					controls: 	'#controls-container-' 	+ currentTrack
				},
				preroll: {
					queue: 	5000,
					line: 	500,
					word: 	200
				},
				offset: (!!track.offset ? track.offset: 0),
				onComplete: priv.nextHS
			};
			$.extend(true, hsParams, settings.hsParams);
			
			state.hs[currentTrack] = new HisaishiEngine(hsParams);
			
			// Not using HisaishiRate in the Player
		}
		$('#scaffold-' + currentTrack).show();
	};
	
	priv.append = function(newSong) {
		state.tracks.push(newSong);
		this.init();
	};
	
	priv.remove = function(id) {
		$('#scaffold-' + id).hide(function(){
			delete state.tracks[id];
			this.init();
		});
	};
	
	$.extend(settings, params);
	
	priv.parseTracks = function() {
		for (var i in state.tracks) {
			if (state.tracks.hasOwnProperty(i)) {
				if (!!state.tracks[i].loaded) continue;
				
				var folder = state.tracks[i].folder,
					lyrics = state.tracks[i].lyrics,
					audio  = state.tracks[i].audio,
					cover  = state.tracks[i].cover;
				
				state.tracks[i].compiledLyrics 	= folder + lyrics;
				state.tracks[i].compiledAudio 	= folder + audio;
				state.tracks[i].compiledCover 	= (cover == null) ? '' : folder + cover;
				
				this.scaffold(i);
				
				state.tracks[i].loaded = true;
			}
		}
		this.setup();
	};
	
	priv.importData = function(data) {
		state.tracks = data.songs;
		state.queue = data.queue;
		priv.parseTracks();
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
		        	
		        	// called whenever the queue gets reordered
		        	reorder: function(e) {
		        		// e.data.queue
		        		// e.data.songs
		        		priv.importData(e.data);
		        	},
		        	
		        	// called whenever *any* track gets played
		        	play: function(e) {
		        		// e.data.queue_id
		        		var oldQueueID = state.current_queue,
		        		newQueueID = e.data.queue_id,
		        		
		        		oldTrackID = state.track,
		        		newTrackID = state.track;
		        		
		        		if (oldQueueID != newTrackID) {
		        			state.current_queue = newQueueID;
		        			foreach (var i in state.queue) {
		        				if (state.queue.hasOwnProperty(i)) {
		        					var q_item = state.queue[i];
									if (q_item.id == newQueueID) {
										newTrackID = q_item.song_id;
										break;
									}
		        				}
		        			}
		        		}
		        		
		        		if (newTrackID != oldTrackID) {
			        		priv.switchHS(newTrackID, true);
		        		}
		        	},
		        	
		        	// called whenever the playing track is paused
		        	pause: function(e) {
		        		state.hs[state.track].pauseSong();
		        	},

		        	// called whenever the playing track is stopped		        	
		        	stop: function(e) {
		        		state.hs[state.track].stopSong();
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