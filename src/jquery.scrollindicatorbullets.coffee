"use strict"

# Expose plugin as an AMD module if AMD loader is present:
(((factory) ->
	if (typeof define == 'function' && define.amd)
		# AMD. Register as an anonymous module.
		define(['jquery', 'waypoints/lib/noframework.waypoints.js'], factory);
	else if (typeof exports == 'object' && typeof require == 'function')
		# Browserify
		factory(require('jquery'), require('waypoints/lib/noframework.waypoints.js'));
	else
		# Browser globals
		factory(jQuery);
)(($) ->

	###
	# scrollIndicatorBullets initializes the bullet navigation on the right side of the screen for a given set of anchor sections.
	# For each anchor section that has an ID, this function creates a bullet. By clicking on a bullet the user scrolls to
	# the referenced pane.
	# The list of scrollable sections panes can hold any kind of element - it's not restricted to actual Drupal panel panes.
	###
	$.fn.scrollIndicatorBullets = (options) ->
		defaults = {
			titleSelector: null # content of matching elements will be used as tooltip titles
			scrollDuration: 400
			touchTitleDelay: 500
			scrollOffset: 50
			waypointOffsetDown: window.innerHeight/3 # Considered 'active' as soon as the top of the block is half way up the screen
			waypointOffsetUp: 50 # Considered 'active' as soon as the top of the block is 50 px fron the top of the screen
			pgKeysEnabled: true # Should pageUp and pageDown keys trigger the jumps inside the navigation?
		}

		settings = $.extend( {}, defaults, options )

		$anchorSections = this.filter(->
			return $(this).height() > 10
		)

		$navTargetSections = $anchorSections.filter('[id]')

		$activeTargetSection = $([])

		# Don't initialize an empty set of anchor items
		if (!$navTargetSections.length)
			return

		scrollTo = ($element) ->
			$activeTargetSection = $element
			history.replaceState({}, '', "#{window.location.pathname}##{$element.attr('id')}") if history.replaceState?
			$('body,html').animate({ scrollTop: ($element.offset().top - settings.scrollOffset) }, settings.scrollDuration, () ->
				activateBulletItemLink($element)
			)

		emptyFilter = ->
			return $.trim($(this).text()) != ''

		###
		# Show titles if bullet is touched for longer that X ms
		# Use touchend event as trigger to scroll
		###
		initTouchDevices = ($bulletItem) ->
			touchTimeout = null
			$bulletItem.on('touchstart.scrollindicator', (event) ->
				touchTimeout = window.setTimeout(()->
					$(event.currentTarget).addClass('show-title')
					touchTimeout = null
					return
				, settings.touchTitleDelay)
			)
			$bulletItem.on('touchend.scrollindicator', (event) ->
				if (touchTimeout)
					window.clearTimeout(touchTimeout)
					scrollTo($(event.currentTarget).find('a:first').data('targetSection'))

				$('.show-title').removeClass('show-title')
			)

		###
		# Show titles on mouseover
		# Use click event as trigger to scroll
		###
		initNonTouchDevices = ($bulletItem, $bulletItemLink, $navigation) ->
			$bulletItem.on('mouseover.scrollindicator mouseout.scrollindicator', ->
				$bulletItem.toggleClass('show-title')
				$navigation.toggleClass('open')
			)
			$bulletItemLink.on('click.scrollindicator', (event) ->
				event.preventDefault()
				scrollTo($(event.currentTarget).data('targetSection'))
			)

		###
		# Initialize the bullet navigation
		# Creates markup and initializes internal data structures.
		###
		initBulletNavigation = ->
			# Create bullet point navigation containers
			$navigationContainer = $('<div>').attr('id', 'scroll-indicator-bullets')
			$navigation = $('<ul>').appendTo($navigationContainer)
			$navTargetSections.each (index, targetSection) ->
				$targetSection = $(targetSection)

				# Ceate doubly linked list of target sections
				if (index > 0)
					$prevTargetSection = $($navTargetSections.get(index-1))
					$prevTargetSection.data('nextTargetSection', $targetSection)
					$targetSection.data('prevTargetSection', $prevTargetSection)

				# Create bullet point markup
				$bulletItemLink = $('<a>').attr('href', "##{$targetSection.attr('id')}")
				$bulletItemLink.addClass('bullet-item-link')
				$bulletItemLink.data('targetSection', $targetSection)
				$targetSection.data('bulletItemLink', $bulletItemLink)

				# add title
				title = $targetSection.find(settings.titleSelector).filter(emptyFilter).first().text()
				if (title != "")
					$bulletItemLink.append($('<span>').addClass('bullet-nav-title').text(title))
				$bulletItemLink.append($('<i>').addClass('circle'))
				$bulletItem = $('<li>')

				if (window.Modernizr? && window.Modernizr.touch)
					initTouchDevices($bulletItem)
				else
					initNonTouchDevices($bulletItem, $bulletItemLink, $navigation)

				$bulletItemLink.appendTo($bulletItem)
				$bulletItem.appendTo($navigation)
			$('body').append($navigationContainer)
			$navTargetSections.first().data('bulletItemLink').addClass('active')


		activateBulletItemLink = ($targetSection) ->
			$('.bullet-item-link.active').removeClass('active')
			if ($targetSection.data('bulletItemLink'))
				$targetSection.data('bulletItemLink').addClass('active')

		###
		# Initializes different waypoints for directions up and down for each section.
		###
		initWaypoints = ->
			$navTargetSections.each((index, element) ->
				new window.Waypoint({
					element: element,
					handler: (direction) ->
						if (direction == 'down')
							$('.bullet-item-link.active').removeClass('active')
							$activeTargetSection = $(this.element)
							activateBulletItemLink($(this.element))
					,
					offset: settings.waypointOffsetDown
				})
			)
			$navTargetSections.slice(1).each((index, element) ->
				new window.Waypoint({
					element: element,
					handler: (direction) ->
						if (direction == 'up')
							$('.bullet-item-link.active').removeClass('active')
							$activeTargetSection = $(this.element)
							activateBulletItemLink($(this.element))
					,
					offset: settings.waypointOffsetUp
				})
			)
			# extra saussage for the top block
			new window.Waypoint({
				element: $navTargetSections.get(0)
				handler: (direction) ->
					if (direction == 'up')
						$('.bullet-item-link.active').removeClass('active')
						$activeTargetSection = $(this.element)
						activateBulletItemLink($(this.element))
				,
				offset: -5
			})

		initPgUpPgDown = ->
			$(window.document).keydown((event) ->
				code = if event.keyCode then event.keyCode else event.which
				if (code == 33 && scrollToPrevTargetSection())
					event.preventDefault()
				else if (code == 34 && scrollToNextTargetSection())
					event.preventDefault()
			)

		###
		# Scrolls to the next section if there is one.
		# This function returns false if there was no next section so the caller can
		# decide on what to do.
		###
		scrollToNextTargetSection = ->
			if ($activeTargetSection && $activeTargetSection.data('nextTargetSection'))
				scrollTo($activeTargetSection.data('nextTargetSection'))
				return true
			else
				return false

		###
		# Scrolls to the previous section if there is one.
		# This function returns false if there was no next section so the caller can
		# decide on what to do.
		###
		scrollToPrevTargetSection = ->
			if ($activeTargetSection && $activeTargetSection.data('prevTargetSection'))
				scrollTo($activeTargetSection.data('prevTargetSection'))
				return true
			else
				return false

		# and finally, initialize the library
		initBulletNavigation()
		initWaypoints()

		if (settings.pgKeysEnabled)
			initPgUpPgDown()

		return {
			scrollToNext: scrollToNextTargetSection
			scrollToPrev: scrollToPrevTargetSection
		}
))
