/* Hisaishi List */

if (HisaishiEngine === undefined) {
	throw {
		type: 'NoHisaishiEngineException',
		message: 'No Hisaishi engine script found.'
	};
}

var HisaishiPlayer = function(params) {
	
	var settings = {
		hsParams: {},
		containers: {
			display: null,
			list: null
		},
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
		
		countdowns: {
			next: null
		},
		
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
	
	priv.scaffoldQueue = function(queueIdent, trackIdent) {
		var fields = ['title', 'artist', 'album', 'karaoke'],
		listitem = $('<li />', {
			id:   'select-track-' + trackIdent
		});
		
		var track = state.tracks[trackIdent];
		
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
	
	priv.stopNextScreen = function() {
		clearInterval(state.countdowns.seconds);
		clearTimeout(state.countdowns.next);
		$('.next-container', settings.containers.display).hide();
		$('.next-container-inner', settings.containers.display).html('');
	};
	
	priv.nextHS = function() {
		// switch HS to next song
		// pop warning
		// wait for 30 seconds
		
		console.log('completed!');
		
		var currentQueueIndex = null,
		nextQueueIndex = 0;
		
		for (var i in state.queue) {
			if (state.queue.hasOwnProperty(i)) {
				var q_item = state.queue[i];
				if (q_item.id == state.current_queue) {
					currentQueueIndex = i;
					nextQueueIndex = +(currentQueueIndex) + 1;
					break;
				}
			}
		}
		
		if (nextQueueIndex >= state.queue.length) {
			return;
		}
		
		if ($('.next-container', settings.containers.display)) {
			var nextContainer = $('<div />', {
				'class': 'next-container'
			});
			nextContainerInner = $('<div />', {
				'class': 'next-container-inner'
			});
			nextContainer.css({
				position: 'absolute',
				top: '0px',
				left: '0px',
				width: '100%',
				height: '100%'
			});
			nextContainer.append(nextContainerInner);
			$(settings.containers.display).append(nextContainer);
		}
		
		if (nextQueueIndex >= 0) {
			var q = state.queue[nextQueueIndex];
			if (!!q) {
				var song = state.tracks[q.song_id];
				
				var currentQueue = state.queue[nextQueueIndex];
				state.current_queue = currentQueue.id;
				
				// @TODO: WE NEED TO UPDATE THE SOURCE OF TRUTH NOW.
				priv.switchHS(currentQueue.song_id, false);
				
				if (!!state.socket) {
					state.socket.send('player_update', {
						queue_id: q.id,
						state: 'pending'
					});
				}
				
				var upcoming = [];
				for (var j = 1; j <= 3; j++) {
					if (j + nextQueueIndex >= state.queue.length) {
						break;
					}
					
					var upq = state.queue[nextQueueIndex + j];
					
					upcoming.push([
						'<li>',
						upq.requester,
						' – ',
						state.tracks[upq.song_id].title,
						'</li>'
					].join(''));
				}
				
				var text = [
					'<p>Next song:</p>',
					'<h2>', song.artist, '</h2>',
					'<h1>', song.title, '</h1>',
					'<p>sung by</p>',
					'<h1>', q.requester, '</h1>',
					'<p>You are up in <span class="secs">30 seconds</span>.</p>'
				];
				
				if (upcoming.length > 0) {
					upcoming.unshift('<ul>');
					upcoming.push('</ul>');
					text = text.concat(upcoming);
				}
				
				$('.next-container-inner', settings.containers.display).html(text.join(''));
				$('.next-container', settings.containers.display).fadeIn();
				
				var mil = 1000,
				timer = 30,
				secs = timer,
				updateSecs = function() {
					$('.next-container-inner .secs', settings.containers.display)
						.text(secs + (secs == 1 ? ' second' : ' seconds'));
				};
				
				state.countdowns.seconds = setInterval(function(){
					secs -= 1;
					updateSecs();
					if (secs == 5) {
						$('.next-container', settings.containers.display).fadeOut(
						5 * mil, 
						function(){
							$('.next-container-inner', settings.containers.display).html('');
						});
					}
					if (secs == 0) {
						clearInterval(state.countdowns.seconds);
					}
				}, mil);
				
				state.countdowns.next = setTimeout(function(){
					priv.switchHS(currentQueue.song_id, true);
				}, timer * mil);
			}
		}
	};
	
	priv.switchHS = function(id, play) {
		if (state.track != null) {
			state.hs[state.track].stopSong();
		}
		
		state.track = id;
		this.setup();
		
		if (!!play) {
			state.hs[state.track].playSong();
		}
	};
	
	priv.setup = function() {
		var currentTrack = state.track;
		if (!!currentTrack) {
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
		}
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
	
	priv.setupArea = function() {
		if ($('.hisaishi-player-alert', settings.containers).length == 0) {
			var alert = $('<div />', {
				'class': 'hisaishi-player-alert'
			});
			$(settings.containers).append(alert);
		}
	};
	
	priv.parseQueue = function() {
		if (settings.containers.list) {
			$(settings.containers.list).children().remove();
		}
		
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
		
		for (var i in state.queue) {
			if (state.queue.hasOwnProperty(i)) {
				var queue_id = state.queue[i].id,
					requester = state.queue[i].requester,
					song_id = state.queue[i].song_id;
				
				priv.scaffoldQueue(queue_id, song_id);
			}
		}
		
		priv.setup();
	};
	
	priv.importData = function(data) {
		for (var i in data.songs) {
			if (data.songs.hasOwnProperty(i)) {
				if (!!state.tracks[i] && !!state.tracks[i].loaded) {
					data.songs[i].loaded = state.tracks[i].loaded;
				}
			}
		}
		
		state.tracks = data.songs;
		state.queue = data.queue;
		priv.parseQueue();
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
		        	
		        	// called whenever the queue gets reordered
		        	reorder: function(e) {
		        		// e.data.queue
		        		// e.data.songs
		        		console.log("reorder");
		        		priv.fetchSource();
		        	},
		        	
		        	queue_update: function(e) {
		        		console.log("queue update");
		        		priv.fetchSource();
		        	},
		        	
		        	// called whenever *any* track gets played
		        	play: function(e) {
		        		// e.data.queue_id
		        		console.log("play " + e.data.queue_id);
		        		
		        		priv.stopNextScreen();
		        		
		        		var oldQueueID = state.current_queue,
		        		newQueueID = e.data.queue_id,
		        		
		        		oldTrackID = state.track || null,
		        		newTrackID = state.track || null;
		        		
		        		if (!!newQueueID && oldQueueID != newQueueID) {
		        			state.current_queue = newQueueID;
		        			for (var i in state.queue) {
		        				if (state.queue.hasOwnProperty(i)) {
		        					var q_item = state.queue[i];
									if (q_item.id == newQueueID) {
										state.current_queue = newQueueID;
										newTrackID = q_item.song_id;
										break;
									}
		        				}
		        			}
		        		}
		        		
		        		if (!!newTrackID && newTrackID != oldTrackID) {
			        		priv.switchHS(newTrackID, true);
		        		}
		        		else {
		        			state.track = newTrackID;
		        			state.hs[state.track].playSong();
		        		}
		        	},
		        	
		        	// called whenever the playing track is paused
		        	pause: function(e) {
		        		console.log("pause");
		        		priv.stopNextScreen();
		        		if (!!state.track) {
		        			state.hs[state.track].pauseSong();
		        		}
		        	},
		        	
		        	// called whenever the playing track is unpaused
		        	unpause: function(e) {
		        		console.log("unpause");
		        		priv.stopNextScreen();
		        		if (!!state.track) {
		        			state.hs[state.track].pauseSong();
		        		}
		        	},

		        	// called whenever the playing track is stopped		        	
		        	stop: function(e) {
		        		console.log("stop");
		        		priv.stopNextScreen();
		        		if (!!state.track) {
		        			state.hs[state.track].stopSong();
		        		}
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
