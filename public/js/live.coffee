$ ->

    padTo2 = (s) ->
        return s unless s.length is 1
        return "0"+s if s.length is 1

    class LiveController

        constructor: ->

            @model = new LiveTweetProducer
            @view = new AppView [37.777222, -122.411111], @model

        now: -> new Date(@startTime + @offset)

        start: ->

            @offset = 0

            @startTime = new Date(Date.now()-0.5*MINUTE).getTime()
            @startTime -= @startTime%(125*SPEED) # Beat quantization fix

            setInterval =>

                $("#time").text "#{padTo2((@now().getHours()).toString())}:#{padTo2(@now().getMinutes().toString())}"
                $("#date").text "#{@now().getDate()} #{@now().getMonth()+1} #{@now().getFullYear()}"

                @model.setCurrentTime @now().getTime()
                @view.draw @now().getTime()

                @offset += SPEED/FPMS

            , 1/FPMS

    live = new LiveController
    live.start()
