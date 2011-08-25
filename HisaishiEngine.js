var HisaishiEngine = function(params) {
	
	var that = {
		state: {
			playing: 	false,
			timer:		null,
			time:		0,
			audio:		null,
			timecodeKey:0
		},
		lyrics: {
			lines: {
			},
			words: {
			},
			timecode: {
			},
			timecodeKeys: []
		},
		classes: {
			wordHighlight: 'word-highlight'
		},
		params: {
			preroll: {
				line: 0,
				word: 0
			},
			offset: 0,
			src: {
				lyrics: null,
				audio: 	null
			},
			containers: {
				lyrics:		null,
				audio:		null,
				controls: 	null
			}
		},
		loaded: {
			lyrics: false,
			audio: 	false
		}
	};
	
	/* Utilities */
	
	that.util = {
		trim: function(txt) {
			return txt.replace(/^[\s\r\n]+/, '').replace(/[\s\r\n]+$/, '');
		},
		convertTime: function(timestamp) {
			var timeParts = timestamp.split(':');
			var ms = (parseInt(timeParts[2], 10) * 10) + 
					 (parseInt(timeParts[1], 10) * 1000) + 
					 (parseInt(timeParts[0], 10) * 60000)
			return ms;
		}
	};
	
	/* Lyrics */
	
	that.parseLyricsFormat = function(raw, callback) {
		var re 		= /\[([0-9:]+)\]([^\[]+)/g;
		var lines 	= raw.split(/[\r\n]/g);
		var i 		= 0, 
			linenum = 0, 
			partnum = 0,
			line, 
			parts,
			time,
			timePreroll;
		
		var that = this;
		var PushPreroll = function(ident) {
			if (!that.lyrics.timecode[timePreroll]) {
				that.lyrics.timecode[timePreroll] = [];
			}
			that.lyrics.timecode[timePreroll].push(ident);
			
			if (that.lyrics.timecodeKeys.indexOf(timePreroll) < 0) {
				that.lyrics.timecodeKeys.push(timePreroll);
			}
		};
		
		for (var i = 0; i < lines.length; i++) {
			line = this.util.trim(lines[i]);
			if (line.length == 0) continue;
			
			this.lyrics.lines[linenum] = {
				id:		'lyricsline-' + linenum,
				words:	[],
				start:	null
			};
			
			re.lastIndex = 0;
			
			do {
				parts = re.exec(line);
				if (!parts || parts.length == 0) break;
				
				time = this.util.convertTime(parts[1]);
				
				this.lyrics.words[partnum] = {
					id: 	'lyricspart-' + partnum,
					phrase: parts[2],
					time:	time
				};
				
				this.lyrics.lines[linenum].words.push(partnum);
				
				if (!this.lyrics.lines[linenum].start) {
					this.lyrics.lines[linenum].start = time;
					
					timePreroll = time - this.params.preroll.line + this.params.offset;
					
					PushPreroll(this.lyrics.lines[linenum].id);
				}
				
				timePreroll = time - this.params.preroll.word + this.params.offset;
				
				PushPreroll(this.lyrics.words[partnum].id);
				
				partnum++;
				
			} while (re.lastIndex < line.length);
			
			linenum++;
		}
		callback();
	};
	
	that.loadLyrics = function() {
		
		if (!this.params.src.lyrics) {
			throw {
				type: 		'HisaishiEngineNoLyricsSrcException',
				message:	'No karaoke lyrics file found.'
			};
		}
		
		var that = this;
		$.ajax({
			type: "GET",
			url: '/proxy',
			data: {
				url: this.params.src.lyrics
			},
			async: true,
			success: function(data){
				that.parseLyricsFormat(data, function(){
					that.loaded.lyrics = true;
					$(that).trigger('checkload');
				});
			}
		});
	};
	
	that.renderLyrics = function() {
		var line, lineData, wordkey, word, wordData;
		
		for (var i in this.lyrics.lines) {
			if (this.lyrics.lines.hasOwnProperty(i)) {
				
				lineData = this.lyrics.lines[i];
				
				line = $('<div />', {
					id: 		lineData.id,
					'class':	'line'
				});
				
				for (var j in lineData.words) {
					if (lineData.words.hasOwnProperty(j)) {
						
						wordkey = lineData.words[j];
						wordData = this.lyrics.words[wordkey];
						
						word = $('<span />', {
							text: 		wordData.phrase,
							id: 		wordData.id,
							'class':	'word'
						});
						
						line.append(word);
					}
				}
				
				line.hide();
				
				$(this.params.containers.lyrics).append(line);
			}
		}
	};
	
	that.animLyrics = function(timecode) {
		var ctx = this.params.containers.lyrics;
		for (var i in this.lyrics.timecode[timecode]) {
			if (i != 'length' && this.lyrics.timecode[timecode].hasOwnProperty(i)) {
				obj = $('#' + this.lyrics.timecode[timecode][i], ctx);
				if (!obj.size()) continue;
				
				if (obj.hasClass('line')) {
					$('.line:visible', ctx).fadeOut(this.params.preroll.line);
					obj.fadeIn(this.params.preroll.line);
				}
				else if (obj.hasClass('word')) {
					$('.' + this.classes.wordHighlight, ctx).removeClass(this.classes.wordHighlight);
					obj.addClass(this.classes.wordHighlight);
				}
			}
		}
	};
	
	/* Audio */
	
	that.loadAudio = function() {
		
		if (!this.params.src.audio) {
			throw {
				type: 		'HisaishiEngineNoAudioSrcException',
				message:	'No karaoke audio file found.'
			};
		}
		
		$('audio').bind('stall', function() {
			var audio = $(this)[0];
			audio.load();
		
			// Threw in these two lines for good measure.
			audio.play();
			audio.pause();
		});
		
		var that = this;
		
		this.state.audio = document.createElement('audio');
		this.state.audio.id = 'bgm';
		this.state.audio.setAttribute('src', this.params.src.audio); 
		this.state.audio.addEventListener("load", function() {
		}, true);
		this.state.audio.load();
		$(this.params.containers.audio).append(this.state.audio);
		
		that.loaded.audio = true;
		$(that).trigger('checkload');
	};
	
	/* Playback */
	
	that.runLoop	= function(timeout) {
		var that = this;
		var CheckEvents = function(){
			
			$('.timer', that.params.containers.controls).text(that.state.time + ',' + that.state.audio.currentTime);
			
			// var expectedTimecode = that.lyrics.timecode
			//this.state.lastTime
			
			var checkTime = that.lyrics.timecodeKeys[that.state.timecodeKey];
			
			if (that.state.time >= checkTime) {
				that.animLyrics(checkTime);
				that.state.timecodeKey++;
			}
			
			that.state.time += 10;
			
			var audioTime = Math.round(that.state.audio.currentTime * 1000);
			if (that.state.time != audioTime) {
				that.state.time = audioTime;
				timeout += that.state.time % 10;
			}
			
			if (!!that.state.playing) {
				that.runLoop();
			}
		};
		
		this.timer = setTimeout(CheckEvents, timeout);
	};
	
	that.playSong 	= function() {
		if (!this.state.playing) {
			that.state.playing = true;
			this.state.audio.play();
			that.runLoop(10);
		}
	};
	
	that.pauseSong 	= function() {
		if (this.state.playing) {
			this.state.playing = false;
			this.state.audio.pause();
			clearTimeout(this.timer);
		}
		else {
			that.playSong();
		}
	};
	
	that.stopSong 	= function() {
		if (this.state.playing) {
			this.pauseSong();
		}
		this.state.audio.currentTime = 0;
		this.state.time 	= 0;
		this.state.lastTime = 0;
		$('.line', this.params.containers.lyrics).hide();
		$('.' + this.classes.wordHighlight, this.params.containers.lyrics).removeClass(this.classes.wordHighlight);
		$('.timer', this.params.containers.controls).text(that.state.time + ',' + that.state.audio.currentTime);
	};
	
	that.seekSong 	= function() {
	};
	
	/* Controls */
	
	that.renderControls = function() {
		var that = this;
		$('<a />', {
			text: 'Play',
			href: '#'
		}).mousedown( function(e){
			e.preventDefault();
			that.playSong();
		}).appendTo(this.params.containers.controls);
		
		$('<a />', {
			text: 'Pause',
			href: '#'
		}).mousedown( function(e){
			e.preventDefault();
			that.pauseSong();
		}).appendTo(this.params.containers.controls);
		
		$('<a />', {
			text: 'Stop',
			href: '#'
		}).mousedown( function(e){
			e.preventDefault();
			that.stopSong();
		}).appendTo(this.params.containers.controls);
		
		$('<span />', {
			text: 		'0',
			'class':	'timer'
		}).appendTo(this.params.containers.controls);
	};
	
	/* Load Everything */
	
	that.loadSong = function() {
		this.loadLyrics();
		this.loadAudio();
	};
	
	/* Render Everything */
	
	that.renderAll = function() {
		if (this.loaded.lyrics && this.loaded.audio) {
			this.renderLyrics();
			this.renderControls();
		}
	};
	
	$.extend(true, that, {params: params});
	
	that.init = function() {
		$(this).bind('checkload', this.renderAll);
		
		if (!!this.params.src.lyrics && !!this.params.src.audio) {
			this.loadSong();
		}
	};
	
	that.init();
	
	return that;
};

var HisaishiList = function(params) {
	var that = {
		params: {
			tracks: {},
			hsParams: {},
			containers: {}
		},
		state: {
			track: null
		},
		hs: {}
	};
	
	that.scaffold = function(ident) {
		
		var track = this.params.tracks[ident];
		
		var display = $('<div />', {
			id: 'scaffold-' + ident,
			'class': 'hisaishi-scaffold'
		}),
		lyrics = $('<div />', {
			id: 'lyrics-container-' + ident,
			'class': 'lyrics-container'
		}),
		audio = $('<div />', {
			id: 'audio-container-' + ident,
			'class': 'audio-container'
		}),
		controls = $('<div />', {
			id: 'controls-container-' + ident,
			'class': 'controls-container'
		});
		display.append(lyrics).append(audio).append(controls);
		
		if (this.params.containers.display) {
			$(this.params.containers.display).append(display);
		}
		
		var fields = ['title', 'artist', 'album'],
		listitem = $('<li />', {
			id:   'select-track-' + ident
		});
		
		for (var i in fields) {
			if (fields.hasOwnProperty(i) && i != 'length') {
				var part = $('<div />', { 
					text: 		track[fields[i]], 
					'class': 	'track-' + fields[i]
				});
				listitem.append(part);
			}
		}
		
		var that = this;
		listitem.click(function(){
			that.switchHS(this.id.replace('select-track-', ''));
		});
		
		if (this.params.containers.list) {
			$(this.params.containers.list).append(listitem);
		}
	};
	
	that.switchHS = function(id) {
		this.hs[this.state.track].stopSong();
		this.state.track = id;
		this.setup();
	};
	
	that.setup = function() {
		var currentTrack = this.state.track;
		$('.hisaishi-scaffold').not('#scaffold-' + currentTrack).hide();
		if (!this.hs[currentTrack]) {
			var track = this.params.tracks[currentTrack];
			
			this.hs[currentTrack] = new HisaishiEngine({
				src: {
					lyrics: track.compiledLyrics,
					audio: 	track.compiledAudio
				},
				containers: {
					lyrics:		'#lyrics-container-' 	+ currentTrack,
					audio:		'#music-container-' 	+ currentTrack,
					controls: 	'#controls-container-' 	+ currentTrack
				},
				preroll: {
					line: 500,
					word: 200
				},
				offset: (!!track.offset ? track.offset: 0)
			});
		}
		$('#scaffold-' + currentTrack).show();
	};
	
	$.extend(true, that, {params: params});
	
	that.init = function() {
		for (var i in this.params.tracks) {
			if (this.params.tracks.hasOwnProperty(i)) {
				if (this.state.track == null) {
					this.state.track = i;
				}
				this.scaffold(i);
				
				var folder = this.params.tracks[i].folder,
					lyrics = this.params.tracks[i].lyrics,
					audio  = this.params.tracks[i].audio;
				
				this.params.tracks[i].compiledLyrics 	= folder + lyrics;
				this.params.tracks[i].compiledAudio 	= folder + audio;
			}
		}
		this.setup();
	};
	
	that.init();
	
	return that;
};