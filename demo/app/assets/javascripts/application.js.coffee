#= require_tree .

$(document).on 'click', '.add-row', (e) ->
  e.preventDefault()

  row = $(this).closest('.row').prev()

  until row.is('.row')
    row = row.prev()
    return if row.length is 0

  new_row = row.clone()
  number = parseInt(new_row.find('.form-control:first').attr('id').match(/(\d+)_\w+$/)[1], 10) + 1

  new_row.find('div, label, input, select').each ->
    elem = $(this)
    elem.removeClass 'error has-error'
    elem.find('.help-block').remove()
    
    if elem.attr('name')
      elem.attr 'name', elem.attr('name').replace(/\[\d+\]/, "[#{number}]")

    if elem.attr('id')
      elem.attr 'id', elem.attr('id').replace(/\_\d+\_/, "_#{number}_")
      elem.val null unless elem.attr('data-copyrow-keepvalue') or elem.attr('type') in ['radio', 'checkbox']

    if elem.attr('for')
      elem.attr 'for', $(this).attr('for').replace(/\_\d+\_/, "_#{number}_")

  new_row.css 'display', 'none'
  row.after new_row
  new_row.slideDown()


$(document).on 'click', '.remove-row', (e) ->
  e.preventDefault()
  row = $(this).closest 'fieldset'
  return if row.closest('form').find('.remove-row').length is 1

  destroy = row.find '.destroy'
  if destroy.length > 0
    destroy.val '1'
    row.slideUp()
  else
    row.slideUp -> row.remove()
