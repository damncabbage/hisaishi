var SortableList = function(selector, params) {
	
	if (!jQuery) {
		throw {
			type: 'NoJQueryException',
			message: 'Required jQuery object not found.'
		};
	}
	
	var $ = jQuery, 
	sel = selector;
	
	var settings = {
		containment: null,
		opacity: 0.6,
		autoInit: false,
		onInit: function(selObj) {
		},
		onUpdate: function(event, ui) {
		},
		onDestroy: function(selObj) {
		}
	};
	$.extend(settings, params);
	
	var pub = {
		init: function() {
			$(sel).sortable({
				axis: 'y',
				containment: settings.containment,
				opacity: settings.opacity,
				update: settings.onUpdate,
				placeholder: "ui-state-highlight"
			});
			settings.onInit($(sel));
		},
		
		destroy: function() {
			$(sel).sortable('destroy');
			settings.onDestroy($(sel));
		}
	};
	
	if (!!settings.autoInit) {
		pub.init();
	}
	
	return pub;
	
};