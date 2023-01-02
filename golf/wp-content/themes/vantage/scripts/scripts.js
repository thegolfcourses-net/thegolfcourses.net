jQuery(function() {

	jQuery('.menu > ul > li:first').addClass('first');
	jQuery('.menu > ul > li:last').addClass('last');

	function switch_to_tab(tab_id) {
		if ( tab_id == '#overview' ) {
			jQuery('#overview-tab').addClass('active-tab');
			jQuery('#overview').show();
			jQuery('#reviews-tab').removeClass('active-tab');
			jQuery('#reviews').hide();
			jQuery('#comments-tab').removeClass('active-tab');
			jQuery('#comments').hide();
		} else if ( tab_id == '#reviews' ) {
			jQuery('#reviews-tab').addClass('active-tab');
			jQuery('#reviews').show();
			jQuery('#overview-tab').removeClass('active-tab');
			jQuery('#overview').hide();
		} else if ( tab_id == '#comments' ) {
			jQuery('#comments-tab').addClass('active-tab');
			jQuery('#comments').show();
			jQuery('#overview-tab').removeClass('active-tab');
			jQuery('#overview').hide();
		}

		if ( 0 === window.location.hash.indexOf('-') ) {
			var yScroll = document.body.scrollTop;
			window.location.hash = tab_id;
			document.body.scrollTop = yScroll;
		}
	}

	if ( 0 === window.location.hash.indexOf('#review') ) {
		switch_to_tab('#reviews');

		if ( jQuery(window.location.hash).length != 0 ) {

			jQuery('html, body').animate({
				scrollTop: ( jQuery(window.location.hash).offset().top -= 35 )
			}, 25);
		}
	}

	if ( 0 === window.location.hash.indexOf('#comment') ) {
		switch_to_tab('#comments');

		if ( jQuery(window.location.hash).length != 0 ) {

			jQuery('html, body').animate({
				scrollTop: ( jQuery(window.location.hash).offset().top -= 35 )
			}, 25);
		}
	}


	jQuery('.tabs > a').click(function(e){
		e.preventDefault();

		switch_to_tab(jQuery(this).attr('href'));
	});

	if ( jQuery('#refine-distance').length ) {
		var RangeSlider = jQuery('#refine-distance .refine-slider');
		RangeSlider.noUiSlider({
			start: Number(RangeSlider.data('start')),
			step: Number(RangeSlider.data('step')),
			range: {
				'min': Number(RangeSlider.data('min')),
				'max': Number(RangeSlider.data('max'))
			}
		});
		RangeSlider.Link('lower').to( jQuery('#refine-distance input[name="radius"]') );
		RangeSlider.Link('lower').to( jQuery('#radius-info') );
	}

	jQuery('#refine-categories').on('change', ':checkbox', function() {
		var $checkbox = jQuery(this);

		if ( $checkbox.prop('checked') ) {
			var $item = $checkbox.closest('li');

			// Uncheck parents
			$item.parents('li').children('label').children(':checkbox')
				.prop('checked', false);

			// Uncheck children
			$item.children('.children').find(':checkbox')
				.prop('checked', false);
		}
	});

	if ( jQuery.fn.colorbox ) {
		jQuery("a[rel='colorbox']").colorbox({transition:'fade',
			current:'',
			slideshow: false,
			slideshowAuto: false,
			maxWidth: '100%',
			maxHeight: '100%',
			scalePhotos: true
		});
	}

	jQuery('.reply-link').click(function(e){
		e.preventDefault();

		jQuery('#reply-review-form').slideUp('fast');
		jQuery('#comment_parent').val('');

		var parent = jQuery(this).closest('.review');

		if (parent.hasClass('replying')) {
			jQuery('.review').removeClass('replying');
			return;
		}

		var parent_comment_id = parent.attr('id').split('-')[1];

		parent.addClass('replying');
		parent.children('.review-content').append(jQuery('#reply-review-form'));
		jQuery('#reply-review-form').slideDown('slow');
		jQuery('#reply-review-form').validate();
		jQuery('#comment_parent').val(parent_comment_id);
	});

	jQuery('.comment-reply-link').click(function(e){
		e.preventDefault();
		jQuery("#add-comment").parent().hide();
	});

	jQuery('#cancel-comment-reply-link').click(function(e){
		e.preventDefault();
		jQuery("#add-comment").parent().show();
	});


	if ( jQuery('#add-review-form').length ) {
		jQuery('#add-review-form').validate({
			submitHandler: ensureReviewRating
		});
	}

	jQuery( document ).on('click', '.listing-faves > a', function(e){
		e.preventDefault();

		var fave = jQuery(this);
		var fave_data = vantage_parse_url_vars(fave.attr('href'));

		var faved_count = jQuery('.listing-unfave-link').length;
		var unfaved_count = 0;

		jQuery('.fave-icon', fave).toggleClass('processing-fave');
		jQuery('.fave-icon', fave).text('Please wait');

		jQuery.post( Vantage.ajaxurl, {
			action: 'vantage_favorites',
			current_url: Vantage.current_url,
			_ajax_nonce: fave_data['ajax_nonce'],
			favorite: fave_data['favorite'],
			listing_id: fave_data['listing_id']
		}, function(data) {

				jQuery('.notice').fadeOut('slow');
				jQuery('#content-inner:first-child').prepend(data.notice);

				fave.replaceWith(data.html);

				if ( data.redirect )
				 	return;

				if ( window.location.pathname.indexOf('favorites') > 0 && fave.hasClass('listing-unfave-link') ) {
					jQuery('article#post-'+fave_data['listing_id']).fadeOut();
					unfaved_count++;

					if ( faved_count == unfaved_count )	location.reload();
				}
		}, "json");

	});

	jQuery( document ).on('click', '.event-faves > a', function(e){
		e.preventDefault();

		var fave = jQuery(this);
		var fave_data = vantage_parse_url_vars(fave.attr('href'));

		var faved_count = jQuery('.event-unfave-link').length;
		var unfaved_count = 0;

		jQuery('.fave-icon', fave).toggleClass('processing-fave');
		jQuery('.fave-icon', fave).text('Please wait');

		jQuery.post( Vantage.ajaxurl, {
			action: 'vantage_event_favorites',
			current_url: Vantage.current_url,
			_ajax_nonce: fave_data['ajax_nonce'],
			favorite: fave_data['favorite'],
			event_id: fave_data['event_id']
		}, function(data) {

				jQuery('.notice').fadeOut('slow');
				jQuery('#content-inner:first-child').prepend(data.notice);

				fave.replaceWith(data.html);

				if ( data.redirect )
				 	return;

				if ( window.location.pathname.indexOf('favorites') > 0 && fave.hasClass('event-unfave-link') ) {
					jQuery('article#post-'+fave_data['event_id']).fadeOut();
					unfaved_count++;

					if ( faved_count == unfaved_count )	location.reload();
				}
		}, "json");

	});

	jQuery( document ).on('click', 'a.listing-delete-link', function(e){ vaDeletePost( e, jQuery(this), 'listing' ); });
	jQuery( document ).on('click', 'a.event-delete-link', function(e){ vaDeletePost( e, jQuery(this), 'event' ); });
});

function vaDeletePost ( e, element, type ) {
	e.preventDefault();

	var data = [], hash;
	var keyValues = element.attr( 'href' ).slice( element.attr( 'href' ).indexOf('?') + 1 ).split('&');
	for( var i = 0; i < keyValues.length; i++ ){
		strings = keyValues[i].split('=');
		data.push( strings[0] );
		data[ strings[0] ] = strings[1];
	}

	var ask = confirm(Vantage.delete_item);
	if (ask) {
		jQuery.post( Vantage.ajaxurl, {
			action: 'vantage_delete_'+type,
			_ajax_nonce: data['ajax_nonce'],
			delete: data['delete']
		}, function(data){
			jQuery( '.notice' ).fadeOut( 'slow' );
			jQuery('#content-inner:first-child').prepend(data.notice);
			if ( 'success' === data.status ) {
				element.closest('article.'+type).remove();
			}
		}, "json" );
	}
}

function ensureReviewRating(form) {
	if ( jQuery('input[name="review_rating"]').val().length > 0 ) {
		form.submit();
	} else {
		jQuery('#review-rating').after('<label for="review_rating" generated="true" class="error rating-error" style="display: block; ">The rating is required.</label>');
		return false;
	}
}

function vantage_map_view() {
	var mapDiv = jQuery('#listing-map');

	if ( !mapDiv.length )
		return;

	function show_map(listing_location) {
		var map = new google.maps.Map(mapDiv.get(0), {
			zoom: 14,
			mapTypeId: google.maps.MapTypeId.ROADMAP
		});

		var marker = new google.maps.Marker({
			map: map
		});

		map.setCenter(listing_location);
		marker.setPosition(listing_location);
	}

	if ( mapDiv.data('lat') ) {
		 show_map(new google.maps.LatLng(mapDiv.data('lat'), mapDiv.data('lng')));
	} else {
		jQuery.getJSON( Vantage.ajaxurl, {
			action: 'vantage_listing_geocode',
			listing_id: mapDiv.data('listing_id')
		}, function(response) {
			show_map(new google.maps.LatLng(response.lat, response.lng));
		} );
	}
}

// Read url parameters and return them as an associative array.
function vantage_parse_url_vars(url){

    var vars = [], hash;
    var hashes = url.slice(url.indexOf('?') + 1).split('&');
    for(var i = 0; i < hashes.length; i++)
    {
        hash = hashes[i].split('=');
        vars.push(hash[0]);
        vars[hash[0]] = hash[1];
    }
    return vars;
}

function colorBoxWidth(){
	var winWidth = jQuery(window).width();
	if ( winWidth >= 1000 ) {
		return '50%';
	} else {
		return '90%';
	}
}

/* Colorbox resize function */
var resizeTimer;
function resizeColorBox() {
	if (resizeTimer)
		clearTimeout(resizeTimer);
	resizeTimer = setTimeout(function() {
		if (jQuery('#cboxOverlay').is(':visible')) {
			jQuery.colorbox.resize({width:colorBoxWidth()});
		}
	}, 300);
}
// Resize Colorbox when resizing window or changing mobile device orientation
jQuery(window).resize(resizeColorBox);
window.addEventListener("orientationchange", resizeColorBox, false);

jQuery(function($){

	if( $('.va-contact-link').length > 0 ) {
		$('.va-contact-link').colorbox({
			maxWidth: colorBoxWidth(),
			width: colorBoxWidth(),
			inline: true
		});

		if ($('#va-contact-form').length > 0) {
			$('#va-contact-form').validate({
				ignore: '.ignore',
				errorClass: 'error',
				errorElement: 'small',
				errorPlacement: function(error, element) {
					error.insertAfter(element);
				},
				highlight: function(element, errorClass, validClass) {
					$(element).closest('label').addClass(errorClass).removeClass(validClass);
				},
				unhighlight: function(element, errorClass, validClass) {
					$(element).closest('label').removeClass(errorClass).addClass(validClass);
				}
			});
		}

		$('#va-contact-send').click(function(e){
			e.preventDefault();
			if ( !$('#va-contact-form').valid() )
				return;

			$.post(Vantage.ajaxurl, {
				action: 'va-contact',
				post_id: $('#va-contact-post_id').val(),
				contact_nonce: $('#va-contact-nonce').val(),
				contact_name: $('#va-contact-name').val(),
				contact_email: $('#va-contact-email').val(),
				contact_phone: $('#va-contact-phone').val(),
				contact_website: $('#va-contact-website').val(),
				contact_message: $('#va-contact-message').val()
			}, function( data ) {
				$('.notice').remove();
				$('#va-contact-form').prepend(data);
				$('.va-contact-link').colorbox.resize();

				setTimeout(function(){
					$('.va-contact-link').colorbox.close();
					$('.notice').remove();
					$('#va-contact-form').find('input[type=text], textarea').val('');
				}, 5000 );
			} );
		});
	}

	// Sort/Filter Dropdown on Event/Listing List pages
	$('.va_sort_list_container').click(function() {
		$(this).toggleClass('active');
	});
	$('.va_sort_list_container').mouseleave(function() {
		$(this).removeClass('active');
	});
	$('.va_sort_list_container li').click(function () {
		$(this).addClass('active').siblings('li').removeClass('active');
		$(this).parents('.va_sort_list_container').find('.selected > p').text( $(this).children('a').text() );
		$(this).parents('.va_sort_list_container').find('select').val( $(this).data('value') );
	});

});
