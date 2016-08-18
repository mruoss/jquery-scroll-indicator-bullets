(function() {
  "use strict";
  (function(factory) {
    if (typeof define === 'function' && define.amd) {
      return define(['jquery', 'waypoints/lib/noframework.waypoints.js'], factory);
    } else if (typeof exports === 'object' && typeof require === 'function') {
      return factory(require('jquery'), require('waypoints/lib/noframework.waypoints.js'));
    } else {
      return factory(jQuery);
    }
  })(function($) {

    /*
    	 * scrollIndicatorBullets initializes the bullet navigation on the right side of the screen for a given set of anchor sections.
    	 * For each anchor section that has an ID, this function creates a bullet. By clicking on a bullet the user scrolls to
    	 * the referenced pane.
    	 * The list of scrollable sections panes can hold any kind of element - it's not restricted to actual Drupal panel panes.
     */
    return $.fn.scrollIndicatorBullets = function(options) {
      var $activeTargetSection, $anchorSections, $navTargetSections, activateBulletItemLink, defaults, emptyFilter, initBulletNavigation, initNonTouchDevices, initPgUpPgDown, initTouchDevices, initWaypoints, scrollTo, scrollToNextTargetSection, scrollToPrevTargetSection, settings;
      defaults = {
        titleSelector: null,
        scrollDuration: 400,
        touchTitleDelay: 500,
        scrollOffset: 50,
        waypointOffsetDown: window.innerHeight / 3,
        waypointOffsetUp: 50,
        pgKeysEnabled: true
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
        $activeTargetSection = $element;
        if (history.replaceState != null) {
          history.replaceState({}, '', window.location.pathname + "#" + ($element.attr('id')));
        }
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
      		 * Use touchend event as trigger to scroll
       */
      initTouchDevices = function($bulletItem) {
        var touchTimeout;
        touchTimeout = null;
        $bulletItem.on('touchstart.scrollindicator', function(event) {
          return touchTimeout = window.setTimeout(function() {
            $(event.currentTarget).addClass('show-title');
            touchTimeout = null;
          }, settings.touchTitleDelay);
        });
        return $bulletItem.on('touchend.scrollindicator', function(event) {
          if (touchTimeout) {
            window.clearTimeout(touchTimeout);
            scrollTo($(event.currentTarget).find('a:first').data('targetSection'));
          }
          return $('.show-title').removeClass('show-title');
        });
      };

      /*
      		 * Show titles on mouseover
      		 * Use click event as trigger to scroll
       */
      initNonTouchDevices = function($bulletItem, $bulletItemLink, $navigation) {
        $bulletItem.on('mouseover.scrollindicator mouseout.scrollindicator', function() {
          $bulletItem.toggleClass('show-title');
          return $navigation.toggleClass('open');
        });
        return $bulletItemLink.on('click.scrollindicator', function(event) {
          event.preventDefault();
          return scrollTo($(event.currentTarget).data('targetSection'));
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
          title = $targetSection.find(settings.titleSelector).filter(emptyFilter).first().text();
          if (title !== "") {
            $bulletItemLink.append($('<span>').addClass('bullet-nav-title').text(title));
          }
          $bulletItemLink.append($('<i>').addClass('circle'));
          $bulletItem = $('<li>');
          if ((window.Modernizr != null) && window.Modernizr.touch) {
            initTouchDevices($bulletItem);
          } else {
            initNonTouchDevices($bulletItem, $bulletItemLink, $navigation);
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
          return $targetSection.data('bulletItemLink').addClass('active');
        }
      };

      /*
      		 * Initializes different waypoints for directions up and down for each section.
       */
      initWaypoints = function() {
        $navTargetSections.each(function(index, element) {
          return new window.Waypoint({
            element: element,
            handler: function(direction) {
              if (direction === 'down') {
                $('.bullet-item-link.active').removeClass('active');
                $activeTargetSection = $(this.element);
                return activateBulletItemLink($(this.element));
              }
            },
            offset: settings.waypointOffsetDown
          });
        });
        $navTargetSections.slice(1).each(function(index, element) {
          return new window.Waypoint({
            element: element,
            handler: function(direction) {
              if (direction === 'up') {
                $('.bullet-item-link.active').removeClass('active');
                $activeTargetSection = $(this.element);
                return activateBulletItemLink($(this.element));
              }
            },
            offset: settings.waypointOffsetUp
          });
        });
        return new window.Waypoint({
          element: $navTargetSections.get(0),
          handler: function(direction) {
            if (direction === 'up') {
              $('.bullet-item-link.active').removeClass('active');
              $activeTargetSection = $(this.element);
              return activateBulletItemLink($(this.element));
            }
          },
          offset: -5
        });
      };
      initPgUpPgDown = function() {
        return $(window.document).keydown(function(event) {
          var code;
          code = event.keyCode ? event.keyCode : event.which;
          if (code === 33 && scrollToPrevTargetSection()) {
            return event.preventDefault();
          } else if (code === 34 && scrollToNextTargetSection()) {
            return event.preventDefault();
          }
        });
      };

      /*
      		 * Scrolls to the next section if there is one.
      		 * This function returns false if there was no next section so the caller can
      		 * decide on what to do.
       */
      scrollToNextTargetSection = function() {
        if ($activeTargetSection && $activeTargetSection.data('nextTargetSection')) {
          scrollTo($activeTargetSection.data('nextTargetSection'));
          return true;
        } else {
          return false;
        }
      };

      /*
      		 * Scrolls to the previous section if there is one.
      		 * This function returns false if there was no next section so the caller can
      		 * decide on what to do.
       */
      scrollToPrevTargetSection = function() {
        if ($activeTargetSection && $activeTargetSection.data('prevTargetSection')) {
          scrollTo($activeTargetSection.data('prevTargetSection'));
          return true;
        } else {
          return false;
        }
      };
      initBulletNavigation();
      initWaypoints();
      if (settings.pgKeysEnabled) {
        initPgUpPgDown();
      }
      return {
        scrollToNext: scrollToNextTargetSection,
        scrollToPrev: scrollToPrevTargetSection
      };
    };
  });

}).call(this);
