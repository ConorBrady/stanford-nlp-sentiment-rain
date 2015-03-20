class TweetAPI

    constructor: ->

        @tweets = []

    _getTweets: (since,completion) ->

        console.log "Requesting data since #{since}"

        $.ajax

            url: "#{location.protocol}//#{location.host}/tweets"
            data:
                limit: 20
                since: since

            success: (response) =>

                console.log "Recieved response from server"

                fixDate = (t) ->
                    t.created_at = Date.parse t.created_at
                    return t

                completion(fixDate t for t in response.data)

            failure: =>

                completion(undefined)


    _addTweetsFromTime: (start,completion) ->

        @_getTweets start, (newTweets) =>

            if newTweets? and newTweets.length > 0
                @tweets.push nt for nt in newTweets
                completion(true)
            else
                completion(false)


    _padTweetsToTime: (end, completion) ->

        if @tweets.length is 0

            completion(false)

        else if _.last(@tweets).created_at > end

            completion(true)

        else

            @_addTweetsFromTime _.last(@tweets).created_at, (success) =>

                if success

                    @_padTweetsToTime end, completion
                else

                    completion(false)


    _filterTweetsByTimes: (start,end) ->

        ( t for t in @tweets when t.created_at > start and t.created_at < end )


    getTweetsBetweenTimes: (start, end, completion) ->

        unless @tweets? and @tweets.length > 0

            @_addTweetsFromTime start, (success) =>

                @_padTweetsToTime end, (success) =>

                    completion @_filterTweetsByTimes(start,end)

        else

            @_padTweetsToTime end, (success) =>

                completion @_filterTweetsByTimes(start,end)

SECOND = 1000
MINUTE = 60*SECOND
HOUR   = 60*MINUTE

class MapView extends Backbone.View

    el: $ "#map"

    initialize: ->

        L.mapbox.accessToken = 'pk.eyJ1IjoiY29ub3JicmFkeSIsImEiOiJiUmRMdDg4In0.WUmSyK7OzgwVNDOGw-DLKw'

    render: ->

        @map = L.mapbox.map 'map', 'examples.3hqcl3di'
            .setView [53.34478682683074, -6.256713864687526], 15

        @featureGroup = L.featureGroup()
            .addTo(@map)

        @map.on 'draw:created', (e) =>
              @featureGroup.addLayer e.layer

        @api = new TweetAPI

    drawAtTime: (time) ->

        @api.getTweetsBetweenTimes time-HOUR, time, (tweets) =>

            for t in tweets
                unless t.circle?

                    t.circle = L.circle [t.lat,t.lon], 10,
                        weight: 0
                        fillColor: '#000'
                        fillOpacity: 1.0

                    t.circle.addTo @featureGroup


                t.circle.setRadius(29/(Math.pow(time-t.created_at,2)+1))

mv = new MapView
mv.render()

n = 0
setInterval ->
    mv.drawAtTime Date.parse('2014-10-24T16:12:00+01:00')+n
    n+=2*HOUR
, 1000
