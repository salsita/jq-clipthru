(($) ->
  $.widget "salsita.clipthru",

    options:
      method: ['clip', 'clip-path']
      dataAttribute: 'jq-clipthru'
      simpleMode: false
      collisionTarget: null
      cloneOnCollision: false # Coming soon.
      keepClonesInHTML: false
      removeAttrOnClone: ['id']
      blockSource: null
      updateOnScroll: true
      updateOnResize: true
      updateOnZoom: true
      updateOnCSSTransitionEnd: false
      autoUpdate: false
      autoUpdateInterval: 100
      broadcastEvents: true
      debug: false

    _create: ->
      @overlayOffset = null
      if @options.collisionTarget
        @collisionTarget = $(@element.find(@options.collisionTarget).get(0))
      else
        @collisionTarget = @element
      @collisionTargetOffset = null
      @allBlocks = null
      @allClones = null
      @collidingBlocks = []
      @_initWidget()

    _initWidget: ->
      _self = this
      @_getAllBlocks()
      if @allBlocks.length > 0
        @_logMessage "#{@allBlocks.length} blocks found", @allBlocks
        @collisionTarget.addClass "#{@options.dataAttribute}-origin"
        @_addIdToBlocks()
        @_attachListeners()
        @_createOverlayClones()
        @refresh()
        clearInterval @autoUpdateTimer?
        if @options.autoUpdate
          @autoUpdateTimer = setInterval (->
            _self.refresh()
          ), @options.autoUpdateInterval
      else
        @_logMessage 'no blocks found'

    _triggerEvent: (name, data) ->
      @element.trigger name, [data]
      @_logMessage name, data

    _logMessage: (name, args) ->
      if @options.debug
        console.debug "#{@options.dataAttribute}: #{name}", args

    # Get all existing blocks.
    _getAllBlocks: ->
      if @options.blockSource
        for cls, blocks of @options.blockSource
          for block in blocks
            $(block).data @options.dataAttribute, cls
            if @allBlocks
              @allBlocks = @allBlocks.add $(block)
            else
              @allBlocks = $(block)
      else
        @allBlocks = $("[data-#{@options.dataAttribute}]")

    # Get offsets of the overlay element.
    _getOverlayOffset: ->
      @overlayOffset = @element.get(0).getBoundingClientRect()
      @collisionTargetOffset = @collisionTarget.get(0).getBoundingClientRect()

    # Give each block a specific id so it's easier to manage the overlay clones.
    _addIdToBlocks: ->
      i = 0
      _self = this
      @allBlocks.each ->
        $(this).data "#{_self.options.dataAttribute}-id", i
        i++

    # Create an overlay clone for each potential block and keep it cached.
    _createOverlayClones: ->
      _self = this
      @allBlocks.each ->
        clone = _self.element.clone()
        if _self.options.removeAttrOnClone
          for attr in _self.options.removeAttrOnClone
            clone.removeAttr attr
        clone.addClass "#{_self.options.dataAttribute}-clone"
        clone.addClass $(this).data _self.options.dataAttribute
        clone.data "#{_self.options.dataAttribute}-id", $(this).data("#{_self.options.dataAttribute}-id")
        if _self.allClones
          _self.allClones = _self.allClones.add clone
        else
          _self.allClones = clone
      if @options.keepClonesInHTML
        @allClones.insertAfter @element
      if @options.broadcastEvents
        @_triggerEvent "clonesCreated.#{@options.dataAttribute}", @allClones

    # Show or hide the colliding overlay clones.
    _updateOverlayClones: ->
      _self = this
      @allClones.each ->
        id = $(this).data("#{_self.options.dataAttribute}-id")
        if _self.collidingBlocks.hasOwnProperty id
          if _self.options.keepClonesInHTML
            $(this).css
              display: _self.element.css 'display'
          else
            if not document.body.contains this
              $(this).insertAfter _self.element
          _self._clipOverlayClone this, _self._getCollisionArea(_self.collidingBlocks[id])
          if _self.options.simpleMode is 'vertical'
            _self._clipOverlayOriginal _self._getRelativeCollision(_self.collidingBlocks[id])
        else
          if _self.options.keepClonesInHTML
            $(this).css
              display: 'none'
          else
            $(this).detach()

      if @collidingBlocks.length is 0
        @element.css
          'clip': 'rect(auto auto auto auto)'

    # Calculate the collision offset values for CSS clip.
    _getCollisionArea: (blockOffset) ->
      clipOffset = []
      clipOffset.push @overlayOffset.height - (@overlayOffset.bottom - blockOffset.top)
      clipOffset.push blockOffset.right - @overlayOffset.left
      clipOffset.push blockOffset.bottom - @overlayOffset.top
      clipOffset.push @overlayOffset.width - (@overlayOffset.right - blockOffset.left)
      return clipOffset

    _getRelativeCollision: (blockOffset) ->
      clipOffset = []
      if @collisionTargetOffset.top <= blockOffset.top
        clipOffset.push 0
        clipOffset.push blockOffset.top - @overlayOffset.top
      else if @collisionTargetOffset.bottom >= blockOffset.bottom
        clipOffset.push @overlayOffset.height - (@overlayOffset.bottom - blockOffset.bottom)
        clipOffset.push @overlayOffset.bottom
      else
        clipOffset = [0, 0]
      return clipOffset

    # Return ids for blocks that collide with the overlay.
    _getCollidingBlocks: ->
      _self = this
      @collidingBlocksOld = @collidingBlocks
      @collidingBlocks = []
      @allBlocks.each ->
        wasCollidedBefore = _self.collidingBlocksOld.hasOwnProperty($(this).data("#{_self.options.dataAttribute}-id"))
        # Does the block collide with the overlay?
        blockOffset = this.getBoundingClientRect()
        if (blockOffset.bottom >= _self.collisionTargetOffset.top) and
        (blockOffset.top <= _self.collisionTargetOffset.bottom) and
        (blockOffset.left <= _self.collisionTargetOffset.right) and
        (blockOffset.right >= _self.collisionTargetOffset.left)
          _self.collidingBlocks[$(this).data("#{_self.options.dataAttribute}-id")] = blockOffset
          if _self.options.broadcastEvents and !wasCollidedBefore
            _self._triggerEvent "collisionStart.#{_self.options.dataAttribute}", this
        else if _self.options.broadcastEvents and wasCollidedBefore
            _self._triggerEvent "collisionEnd.#{_self.options.dataAttribute}", this

    _clipOverlayClone: (clone, offset) ->
      if @options.simpleMode is 'vertical'
        $(clone).css
          'clip': "rect(#{offset[0]}px auto #{offset[2]}px auto)"
      else
        $(clone).css
          'clip': "rect(#{offset[0]}px #{offset[1]}px #{offset[2]}px #{offset[3]}px)"

    _clipOverlayOriginal: (offset) ->
      @element.css
        'clip': "rect(#{offset[0]}px auto #{offset[1]}px auto)"

    _attachListeners: ->
      _self = this
      $(window).on "#{'resize.' + @options.dataAttribute if @options.updateOnResize} #{'scroll.' + @options.dataAttribute if @options.updateOnScroll}", ->
        _self.refresh()

      if @options.updateOnCSSTransitionEnd
        @element.on 'transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd', (event) ->
          if event.originalEvent.propertyName is _self.options.updateOnCSSTransitionEnd
            _self.refresh()

    refresh: ->
      @_getOverlayOffset()
      @_getCollidingBlocks()
      @_updateOverlayClones()

    _destroy: ->
      $(window).off "resize.#{@options.dataAttribute} scroll.#{@options.dataAttribute}"
      @element.off()
      clearInterval @autoUpdateTimer
      @element.css
        'clip': 'auto auto auto auto'
      @allClones.remove()
      @allBlocks = null
      @allClones = null
      @overlayOffset = null
      @collisionTarget = null
      @collisionTargetOffset = null
      @collidingBlocks = null
      @collidingBlocksOld = null

) jQuery