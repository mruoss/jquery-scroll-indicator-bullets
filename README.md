# JQuery Scroll Indicator Bullets

A JQuery plugin to create a scroll indicator bullet navigation on the right side of the screen.

## Requirements

Requires the library [**Waypoints**](https://github.com/imakewebthings/waypoints).

## Usage

The plugin creates bullets for all matching DOM elements that **contain an ID**. The order of the bullet points reflects the order of the elements in the DOM. Therefore the plugin works best with a set of vertically stacked divs.

```javascript
$('div.page-section').scrollIndicatorBullets();
```

### Options

An object defining a number of the following options may be passed to the plugin:

* **titleSelector** - String [null]

  A Selector to retrieve the element's title. The textual content of the first element in the selection is displayed next to the bullet on mouseover.

* **scrollDuration** - int [400]

  Duration in ms of the scroll animation.

* **touchTitleDelay** - int [500]

  Delay in ms for showing the titles on touch devices.

* **scrollOffset** - int [50]

  The offset from the top of the screen to the scrolled section when clicking on the bullet.

* **waypointOffsetDown** - int [window.innerHeight/3]

  When scrolling down: A section becomes active as soon as the top of the block is this far up the screen.

* **waypointOffsetUp** - int [50]

  When scrolling up: A section becomes active as soon as the top of the block is this far down the screen.

```javascript
$('div.page-section').scrollIndicatorBullets({
  titleSelector: '.title,.subtitle'
});
```

## API

The plugin returns an object with a set of functions:

* **scrollToNext()** - Scroll to the next section if there is one.

  This function returns false if there was no next section to scroll to, so the caller can decide on what to do.

* **scrollToPrev()** - Scroll to the previous section if there is one.

  This function returns false if there was no previous section to scroll to, so the caller can decide on what to do.


```javascript
var scrollIndicatorApi = $('div.page-section').scrollIndicatorBullets();

$('.scroll-button').click(function () {
    scrollIndicatorApi.scrollToNext();
});
```
