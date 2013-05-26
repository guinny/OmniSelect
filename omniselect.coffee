# Copyright 2013. All rights reserved.
# Author: Yuning Chai

(($, window) ->
  document = window.document

  class OmniSelect
    constructor: (options) ->
      @_options = $.extend({

        # The container which has all options.
        collection: '.omni-filter-collection'
        # Default element whose value is used for decoding.
        inputUrlArg: ''
        inputElemArg: ''
        # Default element where the encoded value will be stored.
        outputElem: ''
        # The element whose onClick callback resets the structure.
        clearElem: ''

        addFilterLabel: 'add filter'
        removeFilterLabel: 'remove filter'

        onStart: (tour) ->
        onAdd: (tour) ->
        onDelete: (tour) ->
        onSelect: (tour) ->

      }, options)

    init: ->
      # Build the root selector element and an array of HTML forms for
      # each of the labels.
      @_collectionInputs = []
      @_collectionSelect = $('<select>')
      @_collectionSelect.append('<option>', {
          selected: '',
          value: ''})
      @_createCollectionSelect()

      # Initialize the remove filter element.
      @_removeFilterLink = $('<a>', {
          text: @_options.removeFilterLabel
          class: 'remove-filter-link'
          href: '#'
      })

      # Initialize the AddFilter button.
      addFilterLink = $('<a>', {
          text: @_options.addFilterLabel
          class: 'add-filter-link'
          href: '#'
      })
      addFilterLink.click (event) => @_addFilter()
      $(@_options.collection).append addFilterLink


      # Reconstruct the structure from the GET string, if available.
      @decode()
      @_options.onAdd(@) if @_options.onAdd?

    # Serialization into a string. If varSelector.outputElem is defined, also
    # also store the encoded string into that element.
    encode: ->
      str = ''
      opts = $(@_options.collection).children('div')
      counter = 0
      for child in opts
        if $(child).children('div:first').find('select').val() isnt ""
          str += $(child).children('div:first').find('select').val()
          for c in $(child).children('div:not(:first-child)')
            str += ','
            if $(c).is('select,input')
              str += $(c).val()
            else
              str += $(c).find('select,input').val()
          counter += 1
          if (counter < opts.length)
            str += ';'

      if @_options.outputElem isnt ""
        $(@_options.outputElem).val = str

      return str

    # Deserialize a string. This string is found in the following order:
    # 1) argument to this function, 2) inputUrlArg or 3) inputElemArg.
    decode: ->
      # Find the to be decoded string.
      str = ""
      if @_options.inputElemArg isnt ""
        str = $(@_options.outputElem).val
      if @_options.inputUrlArg isnt ""
        str = @_getURIParameter(@_options.inputUrlArg)
      if arguments.length > 0
        str = arguments[0]

      if not str
        str = ""

      opts = str.split(';')
      numFilters = opts.length
      if opts[0] is ""
        numFilters = 0

      if numFilters == 0
        @reset()
        return

      @clear()

      for opt in opts
        values = opt.split(',')
        filter = @_addFilter(false)
        filter.find('select').val values[0]
        @_selectFromCollectionSelect(filter.find('select'), false)

        if filter.children().eq(1).find('select').is('[multiple]')
          rest_values = values.slice(1, values.length)
          filter.children().eq(1).find('select,input').val rest_values
        else
          for j in [1..(filter.children().length - 1)]
            filter.children().eq(j).find('select,input').val values[j]

    # Reset to the default structure.
    reset: ->
      @clear()
      @_addFilter()

    # Clear the entire structure. This function removes all filters.
    # Consider to use reset instead which adds an empty filter after clearing.
    clear: ->
      $(@_options.collection).children('div').remove()


    # Private:

    # Parse the HTML into javascript struture.
    _createCollectionSelect: ->
       counter = 0
       for child in $(@_options.collection).children('div')
         @_collectionSelect.append $('<option>', {
             text: $(child).children('label:first-child').text(),
             value: counter})

         newSelect = []
         for ele in $(child).children(':not(:first-child)')
           eleWrap = $('<div>')
           eleWrap.append ele
           newSelect.push eleWrap[0]
         @_collectionInputs.push newSelect

         ++counter

    # Copy the extra fields after selection an option.
    _selectFromCollectionSelect: (target, runOnSelect=true) ->
      target.parent().parent().children(':not(:first-child):not(a)').remove()

      target.parent().after $(@_collectionInputs[target.val()]).clone()
      if runOnSelect
        @_options.onSelect(@) if @_options.onSelect?

    # Add a new filter.
    _addFilter: (runOnSelect=true) ->
      selectDiv = $('<div>')
      selectDiv.append @_collectionSelect

      clonedSelectDiv = selectDiv.clone()

      clonedSelectDiv.children('select:first-child').change (event)  =>
          @_selectFromCollectionSelect($(event.target))

      clonedSelectDivWrap = $('<div>', {class: 'form-inline'})
      clonedSelectDivWrap.append clonedSelectDiv

      $(@_options.collection).children(':last-child').before clonedSelectDivWrap

      @_updateRemoveFilterButton()
      if runOnSelect
        @_options.onAdd(@) if @_options.onAdd?

      return clonedSelectDivWrap

    _updateRemoveFilterButton: ->
      for child in $(@_options.collection).children('div')
        if $(child).children(':last-child').is('a')
          $(child).children(':last-child').remove()

      if $(@_options.collection).children('div').length > 1
        for child in $(@_options.collection).children('div')
          link = @_removeFilterLink.clone()
          link.click (event) => @_removeFilter(event)
          $(child).append link

    _removeFilter: (event) ->
      $(event.target).parent().remove()
      @_updateRemoveFilterButton()

    _getURIParameter: (name) ->
      sPageURL = window.location.search.substring(1)
      sURLVariables = sPageURL.split('&')
      for i in [0..(sURLVariables.length - 1)]
        sParameterName = sURLVariables[i].split('=')
        if sParameterName[0] == name
          return decodeURIComponent(sParameterName[1])

  window.OmniSelect = OmniSelect

)(jQuery, window)




