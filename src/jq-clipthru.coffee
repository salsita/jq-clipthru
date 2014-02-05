$.fn.clipthru = (options) ->

  # Default settings.
  defaults =
    method: 'cssClip'
    simpleMode: false
    blockSource: []
    dataAttribute: 'jq-clipthru'
    updateOnScroll: true
    updateOnResize: true
    updateOnZoom: true
    autoUpdate: false
    autoUpdateInterval: 100
    debug: false

  # Extend by user settings.
  settings = $.extend(defaults, options)

  # Some top scope properties.
  overlay = $(this)
  overlayOffset = null
  allBlocks = null
  allClones = null
  collidingBlocks = []

  # Get all existing blocks.
  getAllBlocks = ->
    if settings.blockSource.length > 0
      for block in settings.blockSource
        if allBlocks
          allBlocks = allBlocks.add $(block)
        else
          allBlocks = $(block)
    else
      allBlocks = $("[data-#{settings.dataAttribute}]")

  # Give each block a specific id so it's easier to manage the overlay clones.sss
  addIdToBlocks = ->
    i = 0
    allBlocks.each ->
      $(this).data "#{settings.dataAttribute}-id", i
      i++

  # Create an overlay clone for each potential block and keep it cached.
  createOverlayClones = ->
    allBlocks.each ->
      clone = overlay.clone()
      clone.addClass "#{settings.dataAttribute}-clone"
      clone.addClass $(this).data settings.dataAttribute
      clone.data "#{settings.dataAttribute}-id", $(this).data("#{settings.dataAttribute}-id")
      if allClones
        allClones = allClones.add clone
      else
        allClones = clone

  # Show or hide the colliding overlay clones.
  updateOverlayClones = ->
    allClones.each ->
      if collidingBlocks.hasOwnProperty $(this).data("#{settings.dataAttribute}-id")
        if not document.body.contains this
          $(this).insertAfter overlay
        clipOverlayClone this, getCollisionArea(collidingBlocks[$(this).data("#{settings.dataAttribute}-id")])
        if settings.simpleMode is 'vertical'
          clipOverlayOriginal getOtherCollision(collidingBlocks[$(this).data("#{settings.dataAttribute}-id")])
      else
        $(this).detach()
    if collidingBlocks.length is 0
      overlay.removeAttr 'style'

  # Calculate the collision offset values for CSS clip.
  getCollisionArea = (blockOffset) ->
    clipOffset = []
    clipOffset.push overlayOffset.height - (overlayOffset.bottom - blockOffset.top)
    clipOffset.push blockOffset.right - overlayOffset.left
    clipOffset.push blockOffset.bottom - overlayOffset.top
    clipOffset.push overlayOffset.width - (overlayOffset.right - blockOffset.left)
    return clipOffset

  getOtherCollision = (blockOffset) ->
    clipOffset = []
    if overlayOffset.top <= blockOffset.top
      clipOffset.push 0
      clipOffset.push blockOffset.top - overlayOffset.top
    else if overlayOffset.bottom >= blockOffset.bottom
      clipOffset.push overlayOffset.height - (overlayOffset.bottom - blockOffset.bottom)
      clipOffset.push overlayOffset.height
    else
      clipOffset = [0, 0]
    return clipOffset

  # Get offsets of the overlay element.
  getOverlayOffset = ->
    overlayOffset = overlay.get(0).getBoundingClientRect()

  # Return ids for blocks that collide with the overlay.
  getCollidingBlocks = ->
    collidingBlocks = []
    allBlocks.each ->
      # Does the block collide with the overlay?
      blockOffset = this.getBoundingClientRect()
      if (blockOffset.bottom >= overlayOffset.top) and
      (blockOffset.top <= overlayOffset.bottom) and
      (blockOffset.left <= overlayOffset.right) and
      (blockOffset.right >= overlayOffset.left)
        collidingBlocks[$(this).data("#{settings.dataAttribute}-id")] = blockOffset

  clipOverlayClone = (clone, offset) ->
    if settings.simpleMode is 'vertical'
      $(clone).css
        'clip': "rect(#{offset[0]}px auto #{offset[2]}px auto)"
    else
      $(clone).css
        'clip': "rect(#{offset[0]}px #{offset[1]}px #{offset[2]}px #{offset[3]}px)"

  clipOverlayOriginal = (offset) ->
    $(overlay).css
      'clip': "rect(#{offset[0]}px auto #{offset[1]}px auto)"

  refresh = ->
    getOverlayOffset()
    getCollidingBlocks()
    updateOverlayClones()

  attachListeners = ->
    $(window).on "#{'resize' if settings.updateOnResize} #{'scroll' if settings.updateOnScroll}", ->
      refresh()

  init = ->
    getAllBlocks()
    if allBlocks.length > 0
      addIdToBlocks()
      createOverlayClones()
      attachListeners()
      refresh()
      clearInterval autoUpdateTimer?
      if settings.autoUpdate
        autoUpdateTimer = setInterval (->
          refresh()
        ), settings.autoUpdateInterval

  init()