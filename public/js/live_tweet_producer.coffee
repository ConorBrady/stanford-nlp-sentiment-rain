
class window.LiveTweetProducer

    constructor: ->

        @makingRequest = no
        @time = 0
        @lastRecievedTime = 0
        @lastRecievedId = ""


    setTweetCallback: (tc) -> @tc = tc

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

            url: "#{location.protocol}//#{location.host}/live_tweets?since=#{@lastRecievedTime || @time - CIRCLE_DECAY }"

        .done (response) =>

            fixDate = (t) ->
                t.created_at = parseInt(t.created_at)
                return t
            dataset = ( fixDate t for t in response.data when t.id > @lastRecievedId )
            @lastRecievedTime = _.last(dataset).created_at if dataset.length > 0
            @lastRecievedId = _.last(dataset).id if dataset.length > 0

            completion(dataset)

        .fail =>

                completion([])
