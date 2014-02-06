$.fn.clipthru = (options) ->

  # Default settings.
  defaults =
    method: ['clip', 'clip-path']
    dataAttribute: 'jq-clipthru'
    simpleMode: false
    collisionTarget: null
    blockSource: null
    angularScope: null
    angularCompile: null
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
  if settings.collisionTarget
    collisionTarget = $(overlay.find(settings.collisionTarget).get(0))
  else
    collisionTarget = overlay
  collisionTargetOffset = null
  allBlocks = null
  allClones = null
  collidingBlocks = []

  # Get all existing blocks.
  getAllBlocks = ->
    if settings.blockSource
      for block in settings.blockSource
        if allBlocks
          allBlocks = allBlocks.add $(block)
        else
          allBlocks = $(block)
    else
      allBlocks = $("[data-#{settings.dataAttribute}]")

  # Get offsets of the overlay element.
  getOverlayOffset = ->
    overlayOffset = overlay.get(0).getBoundingClientRect()
    collisionTargetOffset = collisionTarget.get(0).getBoundingClientRect()

  # Give each block a specific id so it's easier to manage the overlay clones.
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
      id = $(this).data("#{settings.dataAttribute}-id")
      if collidingBlocks.hasOwnProperty id
        if not document.body.contains this
          $(this).insertAfter overlay
          if settings.angularScope
            settings.angularCompile($(this).contents())(settings.angularScope)
        clipOverlayClone this, getCollisionArea(collidingBlocks[id])
        if settings.simpleMode is 'vertical'
          clipOverlayOriginal getRelativeCollision(collidingBlocks[id])
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

  getRelativeCollision = (blockOffset) ->
    clipOffset = []
    if collisionTargetOffset.top <= blockOffset.top
      clipOffset.push 0
      clipOffset.push blockOffset.top - overlayOffset.top
    else if collisionTargetOffset.bottom >= blockOffset.bottom
      clipOffset.push overlayOffset.height - (overlayOffset.bottom - blockOffset.bottom)
      clipOffset.push overlayOffset.bottom
    else
      clipOffset = [0, 0]
    return clipOffset

  # Return ids for blocks that collide with the overlay.
  getCollidingBlocks = ->
    collidingBlocks = []
    allBlocks.each ->
      # Does the block collide with the overlay?
      blockOffset = this.getBoundingClientRect()
      if (blockOffset.bottom >= collisionTargetOffset.top) and
      (blockOffset.top <= collisionTargetOffset.bottom) and
      (blockOffset.left <= collisionTargetOffset.right) and
      (blockOffset.right >= collisionTargetOffset.left)
        collidingBlocks[$(this).data("#{settings.dataAttribute}-id")] = blockOffset

  clipOverlayClone = (clone, offset) ->
    if settings.simpleMode is 'vertical'
      $(clone).css
        'clip': "rect(#{offset[0]}px auto #{offset[2]}px auto)"
    else
      $(clone).css
        'clip': "rect(#{offset[0]}px #{offset[1]}px #{offset[2]}px #{offset[3]}px)"

  clipOverlayOriginal = (offset) ->
    overlay.css
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
      collisionTarget.addClass "#{settings.dataAttribute}-origin"
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