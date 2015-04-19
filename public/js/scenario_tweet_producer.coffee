
class window.ScenarioTweetProducer

    constructor: ->

        @makingRequest = no
        @time = 0
        @lastRecievedTime = 0


    setTweetCallback: (tc) -> @tc = tc

    reset: -> @time = 0

    setCurrentTime: (time) ->

        @time = time if time > @time

        if not @makingRequest and @time > @lastRecievedTime - 6*SECOND*SPEED
            @makingRequest = yes
            @_getTweets (tweets) =>
                @time = _.last(@time).created_at if _.last(@time)?
                ( @tc(t) for t in tweets )
                @makingRequest = no


    _getTweets: (completion) ->

        $.ajax

            url: "#{location.protocol}//#{location.host}/scenario_tweets"
            data:
                limit: 10
                since: @time

        .done (response) =>

            fixDate = (t) ->
                t.created_at = parseInt(t.created_at)
                t.created_at -= t.created_at % (250*SPEED) # QUANTIZE
                return t

            @lastRecievedTime = fixDate(_.last(response.data)).created_at

            completion(fixDate t for t in response.data)

        .fail =>

            completion([])
