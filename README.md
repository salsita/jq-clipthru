# jq-clipthru

- An element collision detection library that uses CSS clip to display different element design clones over the exact collision area.
- Click [here](//salsita.github.io/jq-clipthru/demo/) for a demo.

`/build` directory contains the latest minified working version that corresponds to the documentation below.

**IMPORTANT** - You can currently only use the library on elements that are either `position: absolute` or `fixed`  
This limitation will be made optional in future versions with SVG `mask/clipPath` masking, but unfortunately SVG masking is a post-process which has serious drawbacks for most cases where you need to interact with the clipped elements.  

## Options
*Example*  
`$('#menu').clipthru({  
  autoUpdate: true,  
  autoUpdateInterval: true  
})`

- `blockSource` - By default, jq-clipthru searches the DOM for elements with a `data-jq-clipthru` attribute and uses those as the source for collision detection. You can instead pass an array of jQuery selectors using this option. Example `{'clone-class': ['.el-1', '#THISDIV:first-child']}`  
- `collisionTarget` - When the element upon which jq-clipthru is called is not the real target of the collision logic. Useful when you're using extra wrappers to position the cloned element and need those with each clone for CSS layout purposes, but don't need to detect collision based on the wrapper's offset. Accepts a jQuery selector string, by default this is the element on which jq-clipthru is instantiated.  
- `keepClonesInHTML` - By default, jq-clipthru removes element clones from the DOM when they are not displayed. This setting will override that behavior and keep the clones in HTML at all times and show/hide them using `display: block/none`. This can be useful for 3rd party DOM manipulation and simplify custom interactions as you can target all the clones yourself at any time. Default `false`  
- `removeAttrOnClone` - Element attributes which should be removed from the clones, useful to prevent `id` collision or other attributes you may not want duplicated. Accepts an array of strings, default `['id']`  
- `updateOnScroll` - Recalculates collisions on scroll event. Default `true`  
- `updateOnResize` - Recalculates collisions on resize event. Default `true`  
- `updateOnCSSTransitionEnd` - Recalculates collision after the base element CSS transition finishes - useful when your transition may change the size of the target, forcing another update. Accepts the name of the CSS transition attribute that should be watched. Example: `'max-height'`  
- `autoUpdate` - Updates the collision detection continuously every xx seconds. Default `false`  
- `autoUpdateInterval` - Frequency of auto updates in milliseconds. Default `100`  
- `debug` - Prints info about it's internals into the browser console, default `false`  

## Public methods
*Examples*  
`$('#menu').clipthru('refresh')`  

- `refresh` - Recalculates everything.   
- `destroy` - Murders the instance.  
  
`jq-clipthru` also broadcasts namespaced events on the target element for collisions along with the target element - `collisionStart.jq-clipthru` `collisionEnd.jq-clipthru`.
