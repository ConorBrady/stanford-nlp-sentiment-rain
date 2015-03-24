$ ->

    padTo2 = (s) ->
        return s unless s.length is 1
        return "0"+s if s.length is 1

    class ScenarioController

        constructor: ->

            @model = new ScenarioTweetProducer
            @view = new AppView [53.34478682683074, -6.256713864687526], @model

            @offset = 0
            @paused = no

            @startTime = Date.parse('2014-10-27T08:00:00+00:00')
            @startTime -= @startTime%(125*SPEED) # Beat quantization fix
            @endTime = @startTime+12*HOUR

            $("#slider").slider
                min: @startTime
                max: @endTime
                start: => @paused = yes
                stop: => @paused = no
                slide: (event,ui) =>
                    @view.reset()
                    @offset = ui.value-@startTime
                    @offset -= @offset%(125*SPEED) # Beat quantization fix :/


        now: -> new Date(@startTime + @offset)

        start: ->

            setInterval =>

                $("#time").text "#{padTo2((@now().getHours()).toString())}:#{padTo2(@now().getMinutes().toString())}"
                $("#date").text "#{@now().getDate()} #{@now().getMonth()+1} #{@now().getFullYear()}"

                unless @paused

                    @model.setCurrentTime @now().getTime()
                    @view.draw @now().getTime()

                    $("#slider").slider('value', @now().getTime())

                    @offset += SPEED/FPMS

                    if @offset+@startTime > @endTime
                        @view.reset()
                        @offset = 0
            , 1/FPMS

    scenario = new ScenarioController
    scenario.start()
