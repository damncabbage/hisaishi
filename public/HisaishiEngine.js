/* Hisaishi Engine */

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
			numlines: 		0,
			lines: 			{},
			words: 			{},
			timecode: 		{},
			timecodeKeys: 	[]
		},
		classes: {
			wordHighlight: 	'word-highlight',
			hidden:			'hidden-line',
			queued: 		'queued-line',
			current:		'current-line',
			complete:		'complete-line'
		},
		params: {
			preroll: {
				queue: 	0,
				line: 	0,
				word: 	0
			},
			transition: {
				line:	200,
				word:	0
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
		var re 		= /\[([0-9:]+)\]([^\[]*)/g;
		var lines 	= raw.split(/[\r\n]/g);
		var i 		= 0, 
			linenum = 0, 
			partnum = 0,
			pre     = this.params.preroll,
			trans	= this.params.transition,
			line, 
			parts,
			time,
			timePreroll;
		
		var that = this;
		
		/**
		 * PushPreroll pushes a new timecode reference to dictate 
		 * that something should happen to a given object with 
		 * reference ident at a given time.
		 * It takes the ident, and the timecode at which to trigger.
		 */
		
		var PushPreroll = function(ident, time, delta) {
			if (!delta) 	delta = 0;
			if (time < 0) 	time = 0;
			
			time -= (delta - that.params.offset);
			
			if (!that.lyrics.timecode[time]) {
				that.lyrics.timecode[time] = [];
			}
			that.lyrics.timecode[time].push(ident);
			
			if (that.lyrics.timecodeKeys.indexOf(time) < 0) {
				that.lyrics.timecodeKeys.push(time);
			}
		};
		
		/* Handle line & word splitting within first loop */
		
		for (var i = 0; i < lines.length; i++) {
			line = this.util.trim(lines[i]);
			if (line.length == 0) continue;
			
			this.lyrics.lines[linenum] = {
				id:		'lyricsline-' + linenum,
				words:	[],
				start:	null,
				raw:	line
			};
			
			re.lastIndex = 0;
			do {
				parts = re.exec(line);
				if (!parts || parts.length == 0) continue;
				
				time = this.util.convertTime(parts[1]);
				
				this.lyrics.words[partnum] = {
					id: 		'lyricspart-' + partnum,
					partnum: 	partnum,
					phrase: 	parts[2],
					time:		time
				};
				
				this.lyrics.lines[linenum].words.push(partnum);
				
				if (!this.lyrics.lines[linenum].start) {
					this.lyrics.lines[linenum].start = time;
				}
				partnum++;
			} while (re.lastIndex < line.length);
			
			linenum++;
			this.lyrics.numlines++;
		}
		
		/* Handle timing within second loop */
		
		linenum = 0, partnum = 0;
		
		for (var i in this.lyrics.lines) {
			if (this.lyrics.lines.hasOwnProperty(i)) {
				var words 		= this.lyrics.lines[i].words,
					lastWord 	= this.lyrics.words[words[words.length - 1]],
					linePrompt 	= pre.line,
					index		= parseInt(i,10),
					startTime 	= this.lyrics.lines[i].start,
					endTime		= lastWord.time;
				
				/* Add three queue points per line */
				
				PushPreroll(this.lyrics.lines[index].id, startTime, pre.queue);
				
				if (index > 0 && index < this.lyrics.numlines - 1) {
					var nextLine 	= this.lyrics.lines[index+1],
						diff 		= nextLine.start - lastWord.time;
					if (diff < linePrompt) {
						linePrompt = diff;
					}
				}
				PushPreroll(this.lyrics.lines[index].id, startTime, linePrompt);
				PushPreroll(this.lyrics.lines[index].id, endTime);
				
				/* Add two queue points per word */
				
				for (var j in words) {
					if (words.hasOwnProperty(j) && j != 'length') {
						var partnum = words[j];
						if (!this.lyrics.words[partnum]) continue;
						
						var word 	= this.lyrics.words[partnum];
						PushPreroll(word.id, word.time, pre.word);
						if (partnum > 0) {
							PushPreroll(this.lyrics.words[partnum-1].id, word.time, pre.word);
						}
					}
				}
			}
		}
		
		/*
		for (var i in this.lyrics.lines) {
			if (this.lyrics.lines.hasOwnProperty(i)) {
				re.lastIndex = 0;
				
				var line = this.lyrics.lines[i].text;
				do {
					parts = re.exec(line);
					time = this.util.convertTime(parts[1]);
					
					this.lyrics.words[partnum] = {
						id: 	'lyricspart-' + partnum,
						phrase: parts[2],
						time:	time
					};
					
					this.lyrics.lines[i].words.push(partnum);
					
					if (!this.lyrics.lines[i].start) {
						this.lyrics.lines[i].start = time;
						
						PushPreroll(this.lyrics.lines[i].id, time, pre.queue);
						
						var linePrompt = pre.line;
						
						if (linenum > 0 && linenum < this.lyrics.lines.length) {
							diff = this.lyrics.lines[linenum+1].start - this.lyrics.words[partnum].time;
							if (diff < linePrompt) {
								diff = linePrompt;
							}
						}
						
						PushPreroll(this.lyrics.lines[i].id, time, linePrompt);
						
						if (linenum > 0) {
							PushPreroll(this.lyrics.lines[i-1].id, time, pre.line);
						}
					}
					
					PushPreroll(this.lyrics.words[partnum].id, time, pre.word);
					if (partnum > 0) {
						PushPreroll(this.lyrics.words[partnum-1].id, time, pre.word);
					}
					
					partnum++;
				} while (re.lastIndex < line.length);
				linenum++;
			}
		}
		*/
		
		this.lyrics.timecodeKeys.sort(function(a, b) {
			return a - b;
		});
		
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
					'class':	'line ' + this.classes.hidden
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
	
	/* Lyrics animation */
	
	that.advanceLine = function(line) {
		var c = this.classes,
			p = this.params.preroll,
			t = this.params.transition,
			map = {
				'current': 	'complete',
				'queued': 	'current',
				'hidden': 	'queued'
			};
			mapFX = {
				'hidden':	'slideDown',
				'current':	'slideUp'
			};
		
		for (var i in map) {
			if (line.hasClass(c[i])) {
				obj.removeClass(c[i]).addClass(c[map[i]]);
				
				if (!!mapFX[i]) {
					obj[mapFX[i]](t.line);
				}
			}
		}
	};
	
	that.advanceWord = function(word) {
		word.toggleClass(this.classes.wordHighlight);
	};
	
	that.animLyrics = function(timecode) {
		var ctx = this.params.containers.lyrics;
		for (var i in this.lyrics.timecode[timecode]) {
			if (i != 'length' && this.lyrics.timecode[timecode].hasOwnProperty(i)) {
				obj = $('#' + this.lyrics.timecode[timecode][i], ctx);
				if (!obj.size()) continue;
				
				if (obj.hasClass('line')) {
					this.advanceLine(obj);
				}
				else if (obj.hasClass('word')) {
					this.advanceWord(obj);
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
			audio.play();
			audio.pause();
		});
		
		var that = this;
		
		this.state.audio = document.createElement('audio');
		this.state.audio.id = 'bgm';
		this.state.audio.setAttribute('src', this.params.src.audio);
		
		// this.state.audio.load();
		$(this.params.containers.audio).append(this.state.audio);
		
		this.state.audio = new MediaElementPlayer('#bgm', {
			// remove or reorder to change plugin priority
			plugins: ['flash'],
			// path to Flash and Silverlight plugins
			pluginPath: '/',
			// name of flash file
			flashName: 'flashmediaelement.swf',
			// rate in milliseconds for Flash and Silverlight to fire the timeupdate event
			// larger number is less accurate, but less strain on plugin->JavaScript bridge
			timerRate: 100,
			success: function (mediaElement, domObject) {
				mediaElement.addEventListener('timeupdate', function(){
					that.setTimerControl();
				}, true);
				
				that.loaded.audio = true;
				$(that).trigger('checkload');
			}
		});
	}; 
	
	/* Playback */
	
	that.runLoop	= function(timeout) {
		var that = this;
		var CheckEvents = function(){
			var checkTime = that.lyrics.timecodeKeys[that.state.timecodeKey];
			
			if (that.state.time >= checkTime) {
				that.animLyrics(checkTime);
				that.state.timecodeKey++;
			}
			
			that.state.time += 10;
			
			var audioTime = Math.round(that.state.audio.getCurrentTime() * 1000);
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
		this.state.audio.setCurrentTime(0);
		this.state.audio.pause();
		this.state.time 				= 0;
		this.state.timecodeKey 			= 0;
		
		var c = this.classes;
		$('.line', this.params.containers.lyrics)
			.hide()
			.removeClass([c.queued, c.current, c.complete].join(' '))
			.addClass(c.hidden);
		$('.' + c.wordHighlight, this.params.containers.lyrics)
			.removeClass(c.wordHighlight);
		
		this.setTimerControl();
	};
	
	that.seekSong 	= function(percent) {
		/*
		var newTime = percent * this.state.audio.media.duration;
		this.state.audio.setCurrentTime(newTime);
		this.playSong();
		*/
	};
	
	/* Controls */

	that.setTimerControl = function() {
		
		var length = this.state.audio.media.duration;
		if (length == NaN) {
			length = 0;
		}
		
		var secs 		= this.state.audio.getCurrentTime(),
			progress 	= (secs / length) * 100,
			roundSecs 	= Math.floor(secs),
			timeParts	= [Math.floor(roundSecs / 60), Math.floor(roundSecs % 60)];
		
		$('.song-range', this.params.containers.controls)
			.attr('value', progress);
		
		$('.timer', this.params.containers.controls)
			.text(timeParts.join('m ') + 's');
	};
	
	that.renderControls = function() {
		var that = this;
		$('<a />', {
		  html: '<img src="/play.png" />',
			title: 'Play',
			href: '#'
		}).mousedown( function(e){
			e.preventDefault();
			that.playSong();
		}).appendTo(this.params.containers.controls);
		
		$('<a />', {
		  html: '<img src="/pause.png" />',
			title: 'Pause',
			href: '#'
		}).mousedown( function(e){
			e.preventDefault();
			that.pauseSong();
		}).appendTo(this.params.containers.controls);
		
		$('<a />', {
		  html: '<img src="/stop.png" />',
			title: 'Stop', 
			href: '#'
		}).mousedown( function(e){
			e.preventDefault();
			that.stopSong();
		}).appendTo(this.params.containers.controls);
		
		$('<progress />', {
			'class': 	'song-range',
			'min':		0,
			'max':		100,
			'value':	0
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

/* Hisaishi List */

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
		hs: {},
		hr: {}
	};
	
	that.scaffold = function(ident) {
		
		var track = this.params.tracks[ident];
		
		var display = $('<div />', {
			id: 'scaffold-' + ident,
			'class': 'hisaishi-scaffold'
		}),
		cover = $('<img />', {
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
		rating = $('<div />', {
			id: 'rating-container-' + ident,
			'class': 'rating-container'
		});
		controlbar
		  .append(controls)
		  .append(rating);
		
		display
			.append(cover)
			.append(lyrics)
			.append(audio)
			.append(controlbar);
		
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
				offset: (!!track.offset ? track.offset: 0)
			};
			$.extend(true, hsParams, this.params.hsParams);
			
			this.hs[currentTrack] = new HisaishiEngine(hsParams);
			
			this.hr[currentTrack] = new HisaishiRate({
				id: this.params.tracks[currentTrack].id,
				containers: {
					rating:		'#rating-container-'	+ currentTrack
				}
			});
		}
		$('#scaffold-' + currentTrack).show();
	};
	
	that.append = function(newSong) {
		this.params.tracks.push(newSong);
		this.init();
	};
	
	that.remove = function(id) {
		$('#scaffold-' + id).hide(function(){
			delete this.params.tracks[id];
			this.init();
		});
	};
	
	$.extend(true, that, {params: params});
	
	that.init = function() {
		for (var i in this.params.tracks) {
			if (this.params.tracks.hasOwnProperty(i)) {
				if (this.state.track == null) {
					this.state.track = i;
				}
				
				if (!!this.params.tracks[i].loaded) continue;
				
				var folder = this.params.tracks[i].folder,
					lyrics = this.params.tracks[i].lyrics,
					audio  = this.params.tracks[i].audio,
					cover  = this.params.tracks[i].cover;
				
				this.params.tracks[i].compiledLyrics 	= folder + lyrics;
				this.params.tracks[i].compiledAudio 	= folder + audio;
				this.params.tracks[i].compiledCover 	= folder + cover;
				
				this.scaffold(i);
				
				this.params.tracks[i].loaded = true;
			}
		}
		this.setup();
	};
	
	that.init();
	
	return that;
};

/* Hisaishi Rater */

var HisaishiRate = function(params) {
	
	var that = {
		params: {
			id: null,
			containers: {
				rating: null
			}
		}
	};
	
	/* Voting */
	
	that.voteCallback = function(vote, comment) {
		$.ajax({
			url: '/song/' + this.params.id + '/vote',
			type: 'POST',
			data: 'vote=' + vote + '&comment=' + comment,
			success: function(){
				alert("Thanks for voting!");
				window.location.href = '/';
			}
		});
	};
	
	that.voteYes = function() {
		this.voteCallback('yes', null);
	};
	
	that.voteNo = function(comment) {
		this.voteCallback('no', comment);
	};
	
	that.voteSkip = function() {
		this.voteCallback('dunno', null);
	};
	
	/* Controls */
	
	that.renderControls = function() {
		var that = this;

    /* Create the controls */

		var yes = $('<a />', {
			html: '<img src="/thumbs-up.png" />',
			title: 'Yes, these lyrics are accurate.',
			href: '#', 
			'class': 'vote-yes'
		}), 
		dunno = $('<a />', {
			html: '<img src="/dunno.png" />',
			title: 'I don\'t know this song, skip to another one.',
			href: '#', 
			'class': 'vote-skip'
		}),
		no = $('<a />', {
			html: '<img src="/thumbs-down.png" />',
			title: 'No, these lyrics are not accurate.',
			href: '#', 
			'class': 'vote-no'
		}),
		comment = $('<div />', {
			html: '<p>What was wrong with it?</p><form><textarea></textarea><input type="submit"></form>',
			'class': 'vote-comment'
		});
		
		/* Attach the listeners */
		
		yes.mousedown( function(e){
			e.preventDefault();
			that.voteYes();
		}).appendTo(this.params.containers.rating);
		
		dunno.mousedown( function(e){
			e.preventDefault();
			that.voteSkip();
		}).appendTo(this.params.containers.rating);
	
		no.mousedown( function(e){
			e.preventDefault();
			comment.show();
		}).appendTo(this.params.containers.rating);

		var textarea = comment.find('textarea');
		
		comment.find('input').mousedown( function(e){
			e.preventDefault();
			that.voteNo(textarea.val());
		})
		
		comment.appendTo(this.params.containers.rating);
	};
	
	$.extend(true, that, {params: params});
	
	that.init = function() {
		this.renderControls();
	};
	
	that.init();
	
	return that;
};