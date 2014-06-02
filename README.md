# jq-clipthru

- An element collision detection library that uses CSS clip to display different element design clones over the exact collision area.
- Just click [here](http://salsita.github.io/jq-clipthru/demo/).

## Options
*Example*  
`$('#menu').clipthru({  
  autoUpdate: true,
  autoUpdateInterval: true
});`

`dataAttribute` - The data- attribute clipthru uses internally and externally, default `jq-clipthru`.  
`blockSource` - By default, jq-clipthru searches the DOM for elements with a `data-jq-clipthru` attribute and uses those as the source for collision detection. You can instead pass an array of jQuery selectors using this option.  
`collisionTarget` - When the element upon which jq-clipthru is called is not the real target of the collision logic. Useful when you're using extra wrappers to position the cloned element, but don't need to detect collision based on the wrapper's offset. Accepts a jQuery selector string, by default these are the elements on which jq-clipthru is instantiated.  
`keepClonesInHTML` - By default, jq-clipthru removes element clones from the DOM when they are not displayed. This setting will override that behavior and keep the clones in HTML at all times and show/hide them using `display: block/none`. This can be useful for 3rd party DOM manipulation and simplify custom interactions as you can target all the clones yourself at any time. Default `false`.  
`removeAttrOnClone` - Element attributes which should be removed from the clones, useful to prevent `id` collision or other attributes you may not want duplicated. Accepts an array of strings, default `['id']`.  
`updateOnScroll` - Recalculates collisions on scroll event. Default `true`.  
`updateOnResize` - Recalculates collisions on resize event. Default `true`.  
`updateOnCSSTransitionEnd` - Recalculates collision after the base element CSS transition finishes - useful when your transition may change the size of the target, forcing another update.  
`autoUpdate` - Updates the collision detection continuously every xx seconds. Default `false`.  
`autoUpdateInterval` - Frequency of auto updates in milliseconds. Default `100`.  
`broadCastEvents` - Broadcasts namespaced events on the target element for collisions along with the target element - `collisionStart.jq-clipthru` `collisionEnd.jq-clipthru`. Default `true`.  
`debug` - Prints info about it's internals into the browser console, default `false`.  


## Public methods
*Examples*  
`$('#menu').clipthru('refresh');`  

`refresh` - Recalculates everything.   
`destroy` - Murders the instance.
