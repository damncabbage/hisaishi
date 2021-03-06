/* Hisaishi Engine */

var HisaishiAudioBound = false;

var HisaishiEngine = function(params) {
  
  var that = {
    state: {
      playing:        false,
      canplay:        false,
      timer:          null,
      time:           0,
      audio:          null,
      timecodeKey:    0,
      errorState:     false
    },
    lyrics: {
      numlines:       0,
      lines:          {},
      words:          {},
      timecode:       {},
      timecodeKeys:   [],
      groups:         {},
      hasGroups:      1
    },
    classes: {
      wordHighlight:  'word-highlight',
      hidden:         'hidden-line',
      queued:         'queued-line',
      current:        'current-line',
      complete:       'complete-line'
    },
    params: {
      preroll: {
        queue:        0,
        line:         0,
        word:         0
      },
      transition: {
        line:         200,
        word:         0
      },
      offset:         0,
      src: {
        lyrics:       null,
        audio:        null
      },
      containers: {
        lyrics:       null,
        audio:        null,
        controls:     null
      },
      onComplete:     function(){},
      onError:        function(){}
    },
    loaded: {
      lyrics:         false,
      audio:          false
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
    },
    renderCSS: function(dict) {
      var css   = [],
        value   = '',
        paramlist;
      for (var className in dict) {
        paramlist = [];
        for (param in dict[className]) {
          value = dict[className][param];
          paramlist.push(param + ': ' + value + ';');
        }
        css.push('.' + className + '{' + paramlist.join('') + '}');
      }
      return css.join('\n');
    }
  };
  
  /* Visual Feedback */
  
  that.triggerBroken = function(reason) {
    if (!!reason) {
      console.log(reason);
    }
    $(this.params.containers.lyrics).parent().addClass('broken');
    that.state.errorState = true;
    that.params.onError();
  };
  
  /* Lyrics */
  
  that.parseLyricsFormat = function(raw, callback) {
    var re     = /\[([0-9:]+)\]([^\[]*)/g,
      fontre  = /<FONT COLOR = "(#[0-9A-F]+)">/g;
    var lines   = raw.split(/[\r\n]/g);
    var i     = 0, 
      linenum = 0, 
      partnum = 0,
      pre     = this.params.preroll,
      trans  = this.params.transition,
      line, 
      parts,
      fontparts,
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
      if (!delta)   delta = 0;
      if (time < 0)   time = 0;
      
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
        id:      'lyricsline-' + linenum,
        words:    [],
        start:    null,
        raw:    line,
        'class':  ''
      };
      
      fontre.lastIndex = 0;
      fontparts = fontre.exec(line);
      if (!!fontparts && fontparts.length > 0) {
        var group = fontparts[1].toLowerCase().replace('#', 'colourgroup-');
        
        this.lyrics.lines[linenum]['class'] = group;
        if (!this.lyrics.groups[group]) {
          this.lyrics.groups[group] = {
            color: fontparts[1]
          };
          this.lyrics.hasGroups++;
        }
        
        line = line.replace(fontparts[0], '');
        this.lyrics.lines[linenum].raw = line;
      }
      
      var parsed = true;
      
      re.lastIndex = 0;
      do {
        parts = re.exec(line);
        if (!parts || parts.length == 0) {
          parsed = false;
          break;
        }
        
        time = this.util.convertTime(parts[1]);
        
        this.lyrics.words[partnum] = {
          id:     'lyricspart-' + partnum,
          partnum:   partnum,
          phrase:   parts[2],
          time:    time
        };
        
        this.lyrics.lines[linenum].words.push(partnum);
        
        if (!this.lyrics.lines[linenum].start) {
          this.lyrics.lines[linenum].start = time;
        }
        partnum++;
      } while (re.lastIndex < line.length);
      
      if (parsed) {
        linenum++;
        this.lyrics.numlines++;
      }
    }
    
    /* Handle timing within second loop */
    
    linenum = 0, partnum = 0;
    
    for (var i in this.lyrics.lines) {
      if (this.lyrics.lines.hasOwnProperty(i)) {
        var words     = this.lyrics.lines[i].words,
          lastWord    = this.lyrics.words[words[words.length - 1]],
          linePrompt   = pre.line,
          index        = parseInt(i,10),
          startTime   = this.lyrics.lines[i].start,
          endTime      = (typeof lastWord != "undefined") ? lastWord.time : 0;
        
        /* Add three queue points per line */
        
        PushPreroll(this.lyrics.lines[index].id, startTime, pre.queue);
        PushPreroll(this.lyrics.lines[index].id, startTime, linePrompt);
        PushPreroll(this.lyrics.lines[index].id, endTime);
        
        /* Add two queue points per word */
        
        for (var j in words) {
          if (words.hasOwnProperty(j) && j != 'length') {
            var partnum = words[j];
            if (!this.lyrics.words[partnum]) continue;
            
            var word   = this.lyrics.words[partnum];
            PushPreroll(word.id, word.time, pre.word);
            if (partnum > 0) {
              PushPreroll(this.lyrics.words[partnum-1].id, word.time, pre.word);
            }
          }
        }
      }
    }
    
    this.lyrics.timecodeKeys.sort(function(a, b) {
      return a - b;
    });
    
    callback();
  };
  
  that.loadLyrics = function() {
    if (!this.params.src.lyrics) {
      throw {
        type:     'HisaishiEngineNoLyricsSrcException',
        message:  'No karaoke lyrics file found.'
      };
    }
    
    var that = this,
        hardFailure = false;
    
    $.ajax({
      type: "GET",
      url: '/proxy',
      data: {
        url: this.params.src.lyrics
      },
      async: true,
      success: function(data){
        console.log(that.params.src.lyrics);
        that.parseLyricsFormat(data, function(){
          that.loaded.lyrics = true;
          $(that).trigger('checkload');
        });
      },
      error: function(){
        if (hardFailure) {
          that.triggerBroken('could not load lyrics');
        }
        else {
          that.parseLyricsFormat('None', function(){
            that.loaded.lyrics = true;
            $(that).trigger('checkload');
          });
        }
      }
    });
  };
  
  that.renderLyrics = function() {
    console.log('renderLyrics');
    var line, 
      lineData, 
      wordkey, 
      word, 
      wordData,
      lc     = this.params.containers.lyrics;
    
    if (this.lyrics.hasGroups > 1) {
      $(lc).addClass('multipart multipart-' + this.lyrics.hasGroups + '-parts');
      
      $('<style />', {
        type:   'text/css',
        scoped: 'scoped',
      }).text(this.util.renderCSS(this.lyrics.groups))
      .appendTo(this.params.containers.lyrics);
      
      $('<div />', {
        'class': 'multipart-line-group default-line-group'
      }).appendTo(this.params.containers.lyrics);
      for (var i in this.lyrics.groups) {
        $('<div />', {
          'class': 'multipart-line-group ' + i + '-line-group'
        }).appendTo(this.params.containers.lyrics);        
      }
    }
    
    for (var i in this.lyrics.lines) {
      if (this.lyrics.lines.hasOwnProperty(i)) {
        
        lineData = this.lyrics.lines[i];
        
        line = $('<div />', {
          id:     lineData.id,
          'class':  ['line', this.classes.hidden, lineData['class']].join(' ')
        });
        
        for (var j in lineData.words) {
          if (lineData.words.hasOwnProperty(j)) {
            
            wordkey = lineData.words[j];
            wordData = this.lyrics.words[wordkey];
            
            word = $('<span />', {
              text:     wordData.phrase,
              id:     wordData.id,
              'class':  'word'
            });
            
            line.append(word);
          }
        }
        
        line.hide();
        
        var target   = $(lc);
        
        if (this.lyrics.hasGroups > 1) {
          target = $('.default-line-group', lc);
          if (!!lineData['class']) {
            target = $('.' + lineData['class'] + '-line-group', lc);
          }
        }
        target.append(line);
      }
    }
  };
  
  /* Lyrics animation */
  
  that.advanceLine = function(line) {
    var c = this.classes,
      p = this.params.preroll,
      t = this.params.transition,
      map = {
        'current':   'complete',
        'queued':   'current',
        'hidden':   'queued'
      };
      mapFX = {
        'hidden':  'slideDown',
        'current':  'slideUp'
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
  
  that.audioBind = function() {
    var audio = $(this)[0];
    audio.load();
    audio.play();
    audio.pause();
  };

  that.loadAudio = function() {
    
    if (!this.params.src.audio) {
      throw {
        type:     'HisaishiEngineNoAudioSrcException',
        message:  'No karaoke audio file found.'
      };
    }
    
    if (!$(this.params.containers.audio).length > 0) {
      throw {
        type:     'HisaishiEngineNoAudioContainerException',
        message:  'Container not ready yet.'
      };
    }
    
    var that = this,
    audioID = 'bgm-' + Math.floor(Math.random() * 9999999)
     + '-' + Math.floor(Math.random() * 9999)
     + '-' + Math.floor(Math.random() * 9999999);
    
    this.state.audio = document.createElement('audio');
    this.state.audio.id = audioID;
    this.state.audio.setAttribute('src', this.params.src.audio);
    
    // this.state.audio.load();
    $(this.params.containers.audio).append(this.state.audio);
    
    this.state.audio = new MediaElementPlayer('#' + audioID, {
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
        
        mediaElement.addEventListener('ended', function(){
          if (!!that.params.onComplete && $.isFunction(that.params.onComplete)) {
            that.params.onComplete();
          }
        }, true);
        
        mediaElement.addEventListener('progress', function(me) {
          try {
            var loaded = parseInt(((me.currentTarget.buffered.end(0) / me.currentTarget.duration) * 100), 10);
            console.log(me.currentTarget.currentSrc + ' : ' + me.currentTarget.buffered.end(0) + ', ' + loaded + '%');
          }
          catch(ex) {
            console.log(me.currentTarget.currentSrc + ' : ' + ex);
          }
        });
        
        mediaElement.addEventListener('canplay', function(me) {
          that.state.canplay = true;
        });
        
          that.loaded.audio = true;
        $(that).trigger('checkload');
      }
    });
  };
  
  /* Playback */
  
  that.runLoop  = function(timeout) {
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
  
  that.playSong   = function() {
    if (!!this.state.errorState) return;
    
    that.renderControls();
    
    if (!this.state.playing) {
      that.state.playing = true;
      if (!!this.state.audio && !!this.state.canplay) {
        this.state.audio.setVolume(1);
        this.state.audio.play();
        that.runLoop(10);
      }
      else {
        that.triggerBroken('playSong: no audio');
      }
    }
  };
  
  that.pauseSong   = function() {
    if (!!this.state.errorState) return;
    if (this.state.playing) {
      this.state.playing = false;
      if (!!this.state.audio) {
        this.state.audio.pause();
      }
      else {
        that.triggerBroken('pauseSong: no audio');
      }
      clearTimeout(this.timer);
    }
    else {
      that.playSong();
    }
  };
  
  that.stopSong = function() {
    if (!!this.state.errorState) return;
    if (this.state.playing) {
      this.pauseSong();
    }
    if (!!this.state.audio) {
      try {
        if (this.state.audio.currentTime != 0 && !!this.state.canplay) {
          this.state.audio.setCurrentTime(0);
        }
        this.state.audio.pause();
      }
      catch(ex) {
        that.triggerBroken('stopSong: exception caught in setCurrentTime ' + ex.message);
      }
    }
    else {
      that.triggerBroken('stopSong: no audio');
    }
    this.state.time         = 0;
    this.state.timecodeKey   = 0;
    
    var c = this.classes;
    $('.line', this.params.containers.lyrics)
      .hide()
      .removeClass([c.queued, c.current, c.complete].join(' '))
      .addClass(c.hidden);
    $('.' + c.wordHighlight, this.params.containers.lyrics)
      .removeClass(c.wordHighlight);
    
    this.setTimerControl();
  };
  
  that.stopSongWithFade = function(callback) {
    var self = that;
    console.log('stopSongWithFade');
    var fadeLen = 2000,
        fadeStep = 200,
        fadeStepLength = fadeStep / fadeLen;
    
    var fade = null
    vol = 1;
    
    var fadeNow = function() {
      vol -= fadeStepLength;
      if (vol < 0) vol = 0;
      if (vol > 1) vol = 1;
      
      console.log(vol);
      self.state.audio.setVolume(vol);
      
      if (vol <= 0) {
        clearInterval(fade);
        self.stopSong();
        if (!!callback && $.isFunction(callback)) {
          callback();
        }
      }
    };
    
    fade = setInterval(fadeNow, fadeStep);
  };
  
  that.seekSong   = function(percent) {
    /*
    var newTime = percent * this.state.audio.media.duration;
    this.state.audio.setCurrentTime(newTime);
    this.playSong();
    */
  };
  
  /* Controls */

  that.setTimerControl = function() {
    
    if (!!this.state.audio) {    
      var length = this.state.audio.media.duration;
      if (length == NaN) {
        length = 0;
      }
      
      var secs     = this.state.audio.getCurrentTime(),
        progress   = (secs / length) * 100,
        roundSecs   = Math.floor(secs),
        timeParts  = [Math.floor(roundSecs / 60), Math.floor(roundSecs % 60)];
      
      try {
        $('.song-range', this.params.containers.controls)
          .attr('value', progress);
      }
      catch (ex) {}
      
      $('.timer', this.params.containers.controls)
        .text(timeParts.join('m ') + 's');
    }
    else {
      this.triggerBroken('setTimerControl: no audio');
    }
  };
  
  that.renderControls = function() {
    console.log('renderControls');
    var that = this;
    
    if ($(this.params.containers.controls).children().length > 0) return;
    
    $('<a />', {
      html: '<img src="/play.png" />',
      title: 'Play',
      href: '#',
      class: 'play-button'
    }).mousedown( function(e){
      e.preventDefault();
      that.playSong();
    }).appendTo(this.params.containers.controls);
    
    $('<a />', {
      html: '<img src="/pause.png" />',
      title: 'Pause',
      href: '#',
      class: 'pause-button'
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
      'class':   'song-range',
      'min':    0,
      'max':    100,
      'value':  0
    }).appendTo(this.params.containers.controls);
    
    $('<span />', {
      text:     '0m 0s',
      'class':  'timer'
    }).appendTo(this.params.containers.controls);
  };
  
  /* Load Everything */
  
  that.loadSong = function() {
    try {
      this.loadLyrics();
      this.loadAudio();
    }
    catch(ex) {
      this.triggerBroken('loadSong: ' + ex.message);
    }
  };
  
  /* Render Everything */
  
  that.renderAll = function() {
    if (this.loaded.lyrics) {
      this.renderLyrics();
    }
    if (this.loaded.audio) {
      this.renderControls();
    }
  };
  
  that.destroy = function() {
    this.state = {
      playing:      false,
      canplay:      false,
      timer:        null,
      time:         0,
      audio:        null,
      timecodeKey:  0,
      errorState:   false
    };
    $(this.params.containers.lyrics).children().remove();
    $(this.params.containers.audio).children().remove();
  };
  
  $.extend(true, that, {params: params});
  
  that.init = function() {
    if (!HisaishiAudioBound) {
      $('audio').live('stall', that.audioBind);
      HisaishiAudioBound = true;
    }
    
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
      containers: {},
      source: null
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
    cover = (track.compiledCover == '') ? '' : $('<img />', {
      id: 'track-image-' + ident,
      src: 'data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
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
    
    var img = $(new Image);
    img.load(function(){
      $('#track-image-' + ident).attr('src', img.src);
    }).error(function(){}).attr('src', track.compiledCover);
    if (img.get(0).complete) {
      $('#track-image-' + ident).attr('src', img.get(0).src);
    }
    
    var fields = ['title', 'artist', 'album', 'karaoke'],
    listitem = $('<li />', {
      id:   'select-track-' + ident
    });
    
    for (var i in fields) {
      if (fields.hasOwnProperty(i) && i != 'length') {
        if (fields[i] == 'karaoke') {
          var karaoke_setting;
          if (track[fields[i]] == 'true') karaoke_setting = 'Karaoke version';
          else if (track[fields[i]] == 'false') karaoke_setting = 'Vocal version';
          else if (track[fields[i]] == 'unknown') karaoke_setting = 'Warning: Karaoke setting not set';
          
          var part = $('<div />', {
            text: karaoke_setting, 
            'class':   'track-' + fields[i]
          });
        } else {
          var part = $('<div />', {
            text: track[fields[i]], 
            'class':   'track-' + fields[i]
          });
        }
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
          audio:   track.compiledAudio
        },
        containers: {
          lyrics:    '#lyrics-container-'   + currentTrack,
          audio:    '#audio-container-'   + currentTrack,
          controls:   '#controls-container-'   + currentTrack
        },
        preroll: {
          queue:   5000,
          line:   500,
          word:   200
        },
        offset: (!!track.offset ? track.offset: 0)
      };
      $.extend(true, hsParams, this.params.hsParams);
      
      this.hs[currentTrack] = new HisaishiEngine(hsParams);
      
      this.hr[currentTrack] = new HisaishiRate({
        id: this.params.tracks[currentTrack].id,
        containers: {
          rating:    '#rating-container-'  + currentTrack
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
  
  that.parseTracks = function() {
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
        
        this.params.tracks[i].compiledLyrics   = folder + lyrics;
        this.params.tracks[i].compiledAudio   = folder + audio;
        this.params.tracks[i].compiledCover   = (cover == null) ? '' : folder + cover;
        
        this.scaffold(i);
        
        this.params.tracks[i].loaded = true;
      }
    }
    this.setup();
  };
  
  that.fetchSource = function() {
    var obj = this;
    $.getJSON(
      this.params.source,
      {},
      function(data){
        obj.tracks = data;
        obj.parseTracks();
      }
    );
  };
  
  that.init = function() {
    if (!!this.tracks && this.tracks.length > 0) {
      this.parseTracks();
    }
    
    if (!!this.params.source) {
      this.fetchSource();
    }
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
  
  that.voteCallback = function(vote, data) {
    var csrf_str = (!!csrf) ? '&_csrf=' + csrf : '';
    $.ajax({
      url: '/song/' + this.params.id + '/vote',
      type: 'POST',
      data: 'vote=' + vote + (!!data ? '&' + data : '') + csrf_str,
      success: function(){
        alert("Thanks for voting!");
        window.location.href = '/';
      }
    });
  };
  
  that.voteYes = function() {
    this.voteCallback('yes');
  };
  
  that.voteNo = function(data) {
    this.voteCallback('no', data);
  };
  
  that.voteSkip = function() {
    this.voteCallback('unknown');
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
    unknown = $('<a />', {
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
      html: '<p>What\'s wrong? (You can select more than one.)</p>' + 
      '<form>' + 
      '<ul></ul>' + 
      '<a href="#">Cancel</a><input type="submit">' + 
      '</form>',
      'class': 'vote-comment'
    });
    
    var commentIndex = 0;
    
    var commentOptions = {
      'none': 'This song has no lyrics.',
      'wrong': 'The lyrics are for another song.',
      'mistimed': 'The lyrics are mistimed.',
      'misspelt': 'The lyrics are misspelt.',
      'details': 'The details for this song are incorrect.',
      'other': 'Something else is wrong.'
    };
    
    var addCheckbox = function(val) {
      var checkbox = $('<input />', {
        type:        'checkbox',
        name:      'reasons[' + commentIndex + '][type]',
        value:      val,
        checked:    false
      });
      
      var reasonInput = $('<textarea />', {
        name:      'reasons[' + commentIndex + '][comment]',
        placeholder:  'Add some more details if you\'d like.',
        rows:      3,
        style:      'display: none'
      });
      
      var showReason = function(elem){
        var ta = $(elem).closest('li').find('textarea');
        if ($(elem).is(':checked')) {
          ta.show();
        }
        else {
          ta.hide();
        }
      };
      
      var label = $('<label />', {
        text: commentOptions[val]
      });
      
      checkbox.change( function(){
        showReason(this);
      });
      
      label.prepend(checkbox);
      
      var li = $('<li />');
      li.append(label).append(reasonInput);
      li.appendTo(comment.find('ul'));
      
      commentIndex++;
    };
    
    for (var i in commentOptions) {
      addCheckbox(i);
    }
    
    /* Attach the listeners */
    
    yes.mousedown( function(e){
      e.preventDefault();
      that.voteYes();
    }).appendTo(this.params.containers.rating);
    
    unknown.mousedown( function(e){
      e.preventDefault();
      that.voteSkip();
    }).appendTo(this.params.containers.rating);
  
    no.mousedown( function(e){
      e.preventDefault();
      $('.pause-button').trigger('mousedown');
      comment.show();
      hiding = 'disabled';
    }).appendTo(this.params.containers.rating);

    var textarea = comment.find('textarea');
    
    comment.find('form').submit( function(e){
      e.preventDefault();
      if($(this).find('input:checked').length == 0) {
        alert('You must select one reason with your error report.');
      } else {
        $(this).find('textarea:hidden').remove();
        that.voteNo($(this).serialize());
      }
    });
    
    comment.find('a').mousedown( function(e){
      e.preventDefault();
      $('.play-button').trigger('mousedown');
      comment.hide();
      hiding = 'enabled';
    });
    
    comment.appendTo(this.params.containers.rating);
  };
  
  $.extend(true, that, {params: params});
  
  that.init = function() {
    this.renderControls();
  };
  
  that.init();
  
  return that;
};