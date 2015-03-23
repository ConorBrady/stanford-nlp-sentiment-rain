
class window.TweetProducer

    constructor: (tweetAccepter) ->
        @makingRequest = no
        @time = 0
        @tweetAccepter = tweetAccepter

    setCurrentTime: (time) -> @time = time if time > @time

    reset: -> @time = 0

    requestMore: ->

        unless @makingRequest
            @makingRequest = yes
            @_getTweets (tweets) =>
                @time = _.last(@time).created_at if _.last(@time)?
                ( @tweetAccepter(t) for t in tweets )
                @makingRequest = no


    _getTweets: (completion) ->

        $.ajax

            url: "#{location.protocol}//#{location.host}/tweets"
            data:
                limit: 10
                since: @time

            success: (response) =>

                fixDate = (t) ->
                    t.created_at = parseInt(t.created_at)
                    return t

                completion(fixDate t for t in response.data)

            failure: =>

                completion([])
