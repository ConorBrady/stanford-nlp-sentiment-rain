
padTo2 = (s) ->
    return s unless s.length is 1
    return "0"+s if s.length is 1

appView = new AppView

offset = 0
pause = false

startTime = Date.parse('2014-10-27T08:00:00+00:00')
endTime = startTime+12*HOUR

$("#slider").slider
    min: startTime
    max: endTime
    start: =>
        pause = true
    stop: =>
        pause = false
    slide: (event,ui) =>
        appView.discardState()
        offset = ui.value-startTime

now = -> new Date(startTime + offset)

setInterval ->

    $("#time").text "#{padTo2((now().getHours()).toString())}:#{padTo2(now().getMinutes().toString())}"
    $("#date").text "#{now().getDate()} #{now().getMonth()+1} #{now().getFullYear()}"

    unless pause

        appView.draw now().getTime()
        $("#slider").slider('value',now().getTime())

        offset += SPEED/FPMS

        if offset+startTime > endTime
            appView.discardState()
            offset = 0
, 1/FPMS
