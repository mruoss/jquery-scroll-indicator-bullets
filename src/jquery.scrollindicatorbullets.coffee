"use strict"

$ = jQuery

###
# scrollIndicatorBullets initializes the bullet navigation on the right side of the screen for a given set of anchor sections.
# For each anchor section that has an ID, this function creates a bullet. By clicking on a bullet the user scrolls to
# the referenced pane.
# The list of scrollable sections panes can hold any kind of element - it's not restricted to actual Drupal panel panes.
###
$.fn.scrollIndicatorBullets= (options) ->
	defaults = {
		titleSelector: null # content of matching elements will be used as tooltip titles
		scrollDuration: 400
		touchTitleDelay: 500
		scrollOffset: 50
		waypointOffsetDown: window.innerHeight/3 # Considered 'active' as soon as the top of the block is half way up the screen
		waypointOffsetUp: 50 # Considered 'active' as soon as the top of the block is 50 px fron the top of the screen
	}

	settings = $.extend( {}, defaults, options );

	$anchorSections = this.filter(->
		return $(this).height() > 10
	)

	$navTargetSections = $anchorSections.filter('[id]')

	$activeTargetSection = $([]);

	# Don't initialize an empty set of anchor items
	if (!$navTargetSections.length)
		return

	scrollTo = ($element) ->
		$('body,html').animate({ scrollTop: ($element.offset().top - settings.scrollOffset) }, settings.scrollDuration, () ->
			activateBulletItemLink($element)
		)

	emptyFilter = ->
		return $.trim($(this).text()) != ''

	###
	# Show titles if bullet is touched for longer that X ms
	###
	initTouchDevices = ($bulletItem) ->
		touchTimeout = null
		$bulletItem.on('touchstart.scrollnav', (event) ->
			touchTimeout = window.setTimeout(()->
				$(event.currentTarget).addClass('show-title')
				return
			, settings.touchTitleDelay)
		)
		$bulletItem.on('touchend.scrollnav', (event) ->
			if (touchTimeout)
				window.clearTimeout(touchTimeout)
			$('.show-title').removeClass('show-title')
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
			$bulletItemLink.click((event) ->
				event.preventDefault()
				scrollTo($(event.currentTarget).data('targetSection'))
			)

			# add title
			title = $targetSection.find(settings.titleSelector).filter(emptyFilter).first().text();
			if (title != "")
				$bulletItemLink.append($('<span>').addClass('bullet-nav-title').text(title))

			$bulletItemLink.append($('<i>').addClass('circle'))

			$bulletItem = $('<li>')
			initTouchDevices($bulletItem) if (Modernizr.touch)
			$bulletItemLink.appendTo($bulletItem)
			$bulletItem.appendTo($navigation)
		$('body').append($navigationContainer)
		$navTargetSections.first().data('bulletItemLink').addClass('active')


	activateBulletItemLink = ($targetSection) ->
		$('.bullet-item-link.active').removeClass('active')
		if ($targetSection.data('bulletItemLink'))
			$activeTargetSection = $targetSection
			$targetSection.data('bulletItemLink').addClass('active')

	###
	# Initializes different waypoints for directions up and down for each section.
	###
	initWaypoints = ->
		$navTargetSections.waypoint((direction) ->
			if (direction == 'down')
				$('.bullet-item-link.active').removeClass('active')
				activateBulletItemLink($(this.element))
		, {offset: settings.waypointOffsetDown})
		$navTargetSections.slice(1).waypoint((direction) ->
			if (direction == 'up')
				$('.bullet-item-link.active').removeClass('active')
				activateBulletItemLink($(this.element))
		, {offset: settings.waypointOffsetUp})
		# extra saussage for the top block
		$navTargetSections.first().waypoint((direction) ->
			if (direction == 'up')
				$('.bullet-item-link.active').removeClass('active')
				activateBulletItemLink($(this.element))
		, {offset: -5})

	scrollToNextTargetSection = ->
		if ($activeTargetSection && $activeTargetSection.data('nextTargetSection'))
			scrollTo($activeTargetSection.data('nextTargetSection'))
			return true
		else if ($navTargetSections.length && ($('html').scrollTop() + $('body').scrollTop() <= 10))
			scrollTo($navTargetSections.first())
			return true
		else
			return false

	initBulletNavigation()
	initWaypoints()

	return {
		scrollToNext: scrollToNextTargetSection
	}
