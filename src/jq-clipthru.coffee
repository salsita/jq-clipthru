(($) ->
  $.widget "salsita.clipthru",

    options:
      method: ['clip', 'clip-path']
      dataAttribute: 'jq-clipthru'
      simpleMode: false
      collisionTarget: null
      cloneOnCollision: false # Coming soon.
      keepClonesInHTML: false
      blockSource: null
      angularScope: null
      angularCompile: null
      updateOnScroll: true
      updateOnResize: true
      updateOnZoom: true
      updateOnCSSTransitionEnd: false
      autoUpdate: false
      autoUpdateInterval: 100
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

      @_getAllBlocks()
      if @allBlocks.length > 0
        @collisionTarget.addClass "#{@options.dataAttribute}-origin"
        @_addIdToBlocks()
        @_createOverlayClones()
        @_attachListeners()
        @refresh()
        clearInterval @autoUpdateTimer?
        if @options.autoUpdate
          @autoUpdateTimer = setInterval (->
            @refresh()
          ), @options.autoUpdateInterval

    # Get all existing blocks.
    _getAllBlocks: ->
      if @options.blockSource
        for block in @options.blockSource
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
        clone.addClass "#{_self.options.dataAttribute}-clone"
        clone.addClass $(this).data _self.options.dataAttribute
        clone.data "#{_self.options.dataAttribute}-id", $(this).data("#{_self.options.dataAttribute}-id")
        if _self.allClones
          _self.allClones = _self.allClones.add clone
        else
          _self.allClones = clone
      if @options.keepClonesInHTML
        @allClones.insertAfter @element
        if @options.angularScope
          @options.angularCompile(@allClones)(@options.angularScope)

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
              if _self.options.angularScope
                _self.options.angularCompile($(this).contents())(_self.options.angularScope)
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
      @collidingBlocks = []
      @allBlocks.each ->
        # Does the block collide with the overlay?
        blockOffset = this.getBoundingClientRect()
        if (blockOffset.bottom >= _self.collisionTargetOffset.top) and
        (blockOffset.top <= _self.collisionTargetOffset.bottom) and
        (blockOffset.left <= _self.collisionTargetOffset.right) and
        (blockOffset.right >= _self.collisionTargetOffset.left)
          _self.collidingBlocks[$(this).data("#{_self.options.dataAttribute}-id")] = blockOffset

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
      $(window).on "#{'resize' if @options.updateOnResize} #{'scroll' if @options.updateOnScroll}", ->
        _self.refresh()

      if @options.updateOnCSSTransitionEnd
        @element.on 'transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd', (event) ->
          if event.originalEvent.propertyName is _self.options.updateOnCSSTransitionEnd
            _self.refresh()

    refresh: ->
      @_getOverlayOffset()
      @_getCollidingBlocks()
      @_updateOverlayClones()

    destroy: ->
      console.log "destroy method called"

) jQuery