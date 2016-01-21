(function() {
  "use strict";
  var $;

  $ = jQuery;


  /*
   * scrollIndicatorBullets initializes the bullet navigation on the right side of the screen for a given set of anchor sections.
   * For each anchor section that has an ID, this function creates a bullet. By clicking on a bullet the user scrolls to
   * the referenced pane.
   * The list of scrollable sections panes can hold any kind of element - it's not restricted to actual Drupal panel panes.
   */

  $.fn.scrollIndicatorBullets = function(options) {
    var $activeTargetSection, $anchorSections, $navTargetSections, activateBulletItemLink, defaults, emptyFilter, initBulletNavigation, initTouchDevices, initWaypoints, scrollTo, scrollToNextTargetSection, settings;
    defaults = {
      titleSelector: null,
      scrollDuration: 400,
      touchTitleDelay: 500,
      scrollOffset: 50,
      waypointOffsetDown: window.innerHeight / 3,
      waypointOffsetUp: 50
    };
    settings = $.extend({}, defaults, options);
    $anchorSections = this.filter(function() {
      return $(this).height() > 10;
    });
    $navTargetSections = $anchorSections.filter('[id]');
    $activeTargetSection = $([]);
    if (!$navTargetSections.length) {
      return;
    }
    scrollTo = function($element) {
      return $('body,html').animate({
        scrollTop: $element.offset().top - settings.scrollOffset
      }, settings.scrollDuration, function() {
        return activateBulletItemLink($element);
      });
    };
    emptyFilter = function() {
      return $.trim($(this).text()) !== '';
    };

    /*
    	 * Show titles if bullet is touched for longer that X ms
     */
    initTouchDevices = function($bulletItem) {
      var touchTimeout;
      touchTimeout = null;
      $bulletItem.on('touchstart.scrollnav', function(event) {
        return touchTimeout = window.setTimeout(function() {
          $(event.currentTarget).addClass('show-title');
        }, settings.touchTitleDelay);
      });
      return $bulletItem.on('touchend.scrollnav', function(event) {
        if (touchTimeout) {
          window.clearTimeout(touchTimeout);
        }
        return $('.show-title').removeClass('show-title');
      });
    };

    /*
    	 * Initialize the bullet navigation
    	 * Creates markup and initializes internal data structures.
     */
    initBulletNavigation = function() {
      var $navigation, $navigationContainer;
      $navigationContainer = $('<div>').attr('id', 'scroll-indicator-bullets');
      $navigation = $('<ul>').appendTo($navigationContainer);
      $navTargetSections.each(function(index, targetSection) {
        var $bulletItem, $bulletItemLink, $prevTargetSection, $targetSection, title;
        $targetSection = $(targetSection);
        if (index > 0) {
          $prevTargetSection = $($navTargetSections.get(index - 1));
          $prevTargetSection.data('nextTargetSection', $targetSection);
          $targetSection.data('prevTargetSection', $prevTargetSection);
        }
        $bulletItemLink = $('<a>').attr('href', "#" + ($targetSection.attr('id')));
        $bulletItemLink.addClass('bullet-item-link');
        $bulletItemLink.data('targetSection', $targetSection);
        $targetSection.data('bulletItemLink', $bulletItemLink);
        $bulletItemLink.click(function(event) {
          event.preventDefault();
          return scrollTo($(event.currentTarget).data('targetSection'));
        });
        title = $targetSection.find(settings.titleSelector).filter(emptyFilter).first().text();
        if (title) {
          $bulletItemLink.append($('<span>').addClass('bullet-nav-title').text());
        }
        $bulletItemLink.append($('<i>').addClass('circle'));
        $bulletItem = $('<li>');
        if (Modernizr.touch) {
          initTouchDevices($bulletItem);
        }
        $bulletItemLink.appendTo($bulletItem);
        return $bulletItem.appendTo($navigation);
      });
      $('body').append($navigationContainer);
      return $navTargetSections.first().data('bulletItemLink').addClass('active');
    };
    activateBulletItemLink = function($targetSection) {
      $('.bullet-item-link.active').removeClass('active');
      if ($targetSection.data('bulletItemLink')) {
        $activeTargetSection = $targetSection;
        return $targetSection.data('bulletItemLink').addClass('active');
      }
    };

    /*
    	 * Initializes different waypoints for directions up and down for each section.
     */
    initWaypoints = function() {
      $navTargetSections.waypoint(function(direction) {
        if (direction === 'down') {
          $('.bullet-item-link.active').removeClass('active');
          return activateBulletItemLink($(this.element));
        }
      }, {
        offset: settings.waypointOffsetDown
      });
      $navTargetSections.slice(1).waypoint(function(direction) {
        if (direction === 'up') {
          $('.bullet-item-link.active').removeClass('active');
          return activateBulletItemLink($(this.element));
        }
      }, {
        offset: settings.waypointOffsetUp
      });
      return $navTargetSections.first().waypoint(function(direction) {
        if (direction === 'up') {
          $('.bullet-item-link.active').removeClass('active');
          return activateBulletItemLink($(this.element));
        }
      }, {
        offset: -5
      });
    };
    scrollToNextTargetSection = function() {
      if ($activeTargetSection && $activeTargetSection.data('nextTargetSection')) {
        scrollTo($activeTargetSection.data('nextTargetSection'));
        return true;
      } else if ($navTargetSections.length && ($('html').scrollTop() + $('body').scrollTop() <= 10)) {
        scrollTo($navTargetSections.first());
        return true;
      } else {
        return false;
      }
    };
    initBulletNavigation();
    initWaypoints();
    return {
      scrollToNext: scrollToNextTargetSection
    };
  };

}).call(this);
