reload_quiz_image = ->
  image = $('#quiz-preview-image')
  if image.length != 0
    quiz_id = image.data('id')
    preview_path = '/assets/quiz-' + quiz_id + '.png'
    date = new Date
    image.attr 'src', preview_path + '?' + date.getTime()
  return

# toggle results display for answered questions in an active quiz

$(document).on 'click', '[id^="toggle_results-"]', ->
  round_id = this.id.replace('toggle_results-','')
  status = $(this).data('status')
  color = $(this).data('color')
  if status == 'reduced'
    $('#reduced-' + round_id).hide 400
    $('#body-' + round_id).addClass color
    $('#toggle_message-' + round_id).empty().append 'ausblenden'
    $('#results-' + round_id).show 800, ->
      $('#toggle_results-' + round_id).data 'status', 'extended'
      return
   else
     $('#results-' + round_id).hide 800
     $('#body-' + round_id).removeClass('bg-correct').removeClass 'bg-incorrect'
     $('#toggle_message-' + round_id).empty().append 'Details'
     $('#reduced-' + round_id).fadeIn 800, ->
       $('#toggle_results-' + round_id).data 'status', 'reduced'
       return

# reload quiz image after page load

$(document).on 'turbolinks:load', reload_quiz_image

# highlight 'Ungespeicherte Änderungen' if quiz top is selected

$(document).on 'change', '#quiz-top-select', ->
  $('#quiz-basics-options').removeClass("no_display")
  $('#quiz-basics-warning').removeClass("no_display")

# highlight 'Ungespeicherte Änderungen' if quiz level is changed

$(document).on 'change', '#level', ->
  $('#quiz-basics-options').removeClass("no_display")
  $('#quiz-basics-warning').removeClass("no_display")


# restore status quo if editing of quiz basics is cancelled

$(document).on 'click', '#quiz-basics-cancel', (evt) ->
    $.ajax Routes.cancel_quiz_basics_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: $(this).data('id')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")

# reveal explanations for answers

$(document).on 'click', '[id^="reveal-explanation-"]', ->
  $('#' + this.id.replace('reveal-','')).removeClass("no_display")
  $('#' + this.id.replace('reveal-explanation','feedback')).removeClass("no_display")
  $(this).remove()

# reveal hint for solution

$(document).on 'click', '[id^="reveal-hint-"]', ->
  $('#' + this.id.replace('reveal-','')).removeClass("no_display")
  $(this).remove()
