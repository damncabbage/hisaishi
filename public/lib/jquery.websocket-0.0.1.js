/*
 * jQuery Web Sockets Plugin v0.0.1
 * http://code.google.com/p/jquery-websocket/
 *
 * This document is licensed as free software under the terms of the
 * MIT License: http://www.opensource.org/licenses/mit-license.php
 * 
 * Copyright (c) 2010 by shootaroo (Shotaro Tsubouchi).
 */
(function($){
$.extend({
	websocketSettings: {
		open: function(){},
		close: function(){},
		message: function(){},
		options: {},
		events: {}
	},
	websocket: function(url, s) {
		/*var ws = ReconnectingWebSocket ? new ReconnectingWebSocket( url ) : {
			send: function(m){ return false },
			close: function(){}
		};*/
		var ws = new ReconnectingWebSocket(url);
		ws._settings = $.extend($.websocketSettings, s);

		ws.onopen = $.proxy($.websocketSettings.open, this);
		ws.onclose = $.proxy($.websocketSettings.close, this);
		ws.onmessage = $.proxy(function(e) {
			$.websocketSettings.message(e)
			var m = $.parseJSON(e.data);
			var h = $.websocketSettings.events[m.type];
			if (h) h.call(this, m);
		}, this);

		ws._send = ws.send;
		ws.send = function(type, data) {
			var m = {type: type};
			m = $.extend(true, m, $.extend(true, {}, $.websocketSettings.options, m));
			if (data) m['data'] = data;
			return this._send($.toJSON(m));
		}
		$(window).unload(function(){ ws.close(); ws = null });
		return ws;
	}
});
})(jQuery);
