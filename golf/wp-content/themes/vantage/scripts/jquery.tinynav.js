/* 
 * http://tinynav.viljamis.com v1.1 by @viljamis
 * https://github.com/viljamis/TinyNav.js
 *
 * Licensed under the MIT license.
 *
 * Copyright (c) 2011-2012 Viljami Salminen, http://viljamis.com/
*/
/**
 * Forked by AppThemes on 01/15/2013
 */

(function ($, window, i) {
	$.fn.tinyNav = function (options) {

		// Default settings
		var settings = $.extend({
			'active' : 'selected', // String: Set the "active" class
			'header' : '', // String: Specify text for "header" and show header instead of the active item
			'header_href' : '', // String: Specify url for "header"
			'force_header' : false, // Force "header" regardless of "active" item
			'indent' : '-', // The indent character that shows the nesting of option elemenets.
			'label' : '', // String: sets the <label> text for the <select> (if not set, no label will be added)
			'after' : '',
			'before': '',
			'append': '',
			'excluded' : [],
		}, options);
	
		return this.each(function () {

			// Used for namespacing
			i++;

			var $nav = $(this),
				// Namespacing
				namespace = 'tinynav',
				namespace_i = namespace + i,
				l_namespace_i = '.l_' + namespace_i,
				$select = $('<select/>').attr("id", namespace_i).addClass(namespace + ' ' + namespace_i);

			var is_excluded = function( that ) {
				var key = '';
				for (key in settings.excluded) {
					if ( that.parents( settings.excluded[key] ).length == 1 ) { 
						return true;
					}
				}
				return false;
			}

			if ($nav.is('ul,ol')) {

				if (settings.header !== '') {
					if (settings.header_href !== '') {
						$select.append(
							$('<option/>').text(settings.header).val(settings.header_href)
						);
					} else {
						$select.append(
							$('<option/>').text(settings.header)
						);
					}
				}

				// Build options
				var options = '';

				$nav
					.addClass('l_' + namespace_i)
					.find('li > a')
					.each(function () {
						if( !is_excluded( $(this) ) ) {
							var _href = $(this).attr('href') ? $(this).attr('href') : '';
							var _disabled = $(this).attr('href') ? '' : ' disabled="disabled" ';
							options += '<option value="' + _href + '"' + _disabled;
							if ( $(this).parent('li').hasClass( settings.active ) ) {
								options += ' selected="selected" ';
							} 
							options += '>';
							var j;
							for (j = 0; j < $(this).parents('ul, ol').length - 1; j++) {
								options += settings.indent;
							}
							options += ' ' + $(this).text() + '</option>';
						}
					});

				// Append options into a select
				$select.append(options);

				// Change window location
				$select.change(function () {
					if ( $(this).val().length > 0 ) { 
						window.location.href = $(this).val();
					}
				});

				// Inject select
				if ( settings.after.length > 0 )  {
					$(settings.after).after($select);
				} else if ( settings.before.length > 0 )  {
					$(settings.before).before($select);
				} else if ( settings.append.length > 0 )  {
					$(settings.append).append($select);
				} else {
					$(l_namespace_i).after($select);
				}

				// Inject label
				if (settings.label) {
					$select.before(
						$("<label/>")
							.attr("for", namespace_i)
							.addClass(namespace + '_label ' + namespace_i + '_label')
							.append(settings.label)
					);
				}

			}

		});

	};
})(jQuery, this, 0);
