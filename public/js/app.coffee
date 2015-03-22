assert = (condition, message) ->
    if not condition
        throw new Error( message || "Assertion failed" )

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
                    t.created_at = parseInt(t.created_at)
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

        @tweets = ( t for t in @tweets when ( t.created_at > start || t.circle? ) )
        ( t for t in @tweets when t.created_at < end )


    clearTweets: ->

        @tweets = []

    getTweetsBetweenTimes: (start, end, completion) ->

        unless @tweets? and @tweets.length > 0

            @_addTweetsFromTime start, (success) =>

                @_padTweetsToTime end, (success) =>

                    completion @_filterTweetsByTimes(start,end)

        else

            @_padTweetsToTime end, (success) =>

                completion @_filterTweetsByTimes(start,end)
MILLISECOND = 1
SECOND = 1000*MILLISECOND
MINUTE = 60*SECOND
HOUR   = 60*MINUTE
DAY    = 24*HOUR

SPEED = 1*MINUTE/SECOND # 5 minutes of time per second real time
FPS = 12
FPMS = FPS/SECOND

CIRCLE_DECAY = 6*SECOND*SPEED # 6 seconds of real time
CIRCLE_RADIUS = 70

padTo2 = (s) ->
    return s unless s.length is 1
    return "0"+s if s.length is 1

class SoundSource

    constructor: ( value, audiolet ) ->

        @oldPan = 0.5

        @scale = new MajorScale()
        frequency1 = @scale.getFrequency Math.floor(value*16.0), 65.4064, 2
        frequency3 = @scale.getFrequency Math.floor(value*16.0)+4, 65.4064, 2

        @sine1 = new Triangle audiolet, frequency1
        @sine3 = new Sine audiolet, frequency3

        @gain = new Multiply audiolet, 0
        @sum = new Add audiolet
        @pad = new Multiply audiolet, 1
        @pan = new Pan audiolet
        @env = new ADSREnvelope audiolet, 0, 0.01, 0.2, 0.02, 3.0

        @sine1.connect @sum
        @sine3.connect @sum, 0, 1

        @env.connect @gain, 0, 1
        @sum.connect @gain
        @gain.connect @pad
        @pad.connect @pan
        @pan.connect audiolet.output


    setVolume: (level) ->
        console.log "Setting volume #{level}"
        @pad.value.setValue Math.min(level,1.0)

    trigger: ->

        @env.gate.setValue 1
        @env.gate.setValue 0

    setPan: (pan) ->

        unless @oldPan is pan
            @pan.pan.setValue pan
            @oldPan = pan

    destroy: ->

        @sine1.remove()
        @sine3.remove()
        @sum.remove()
        @gain.remove()
        @pan.remove()
        @env.remove()

class MapView

    el: $ "#map"

    constructor: ->

        L.mapbox.accessToken = 'pk.eyJ1IjoiY29ub3JicmFkeSIsImEiOiJwTHkxcE9nIn0.tQZaXyeR81SGW8XhtmwhPQ'

        @api = new TweetAPI
        @audiolet = new Audiolet()

    render: ->

        @map = L.mapbox.map 'map', 'examples.3hqcl3di',
            minZoom: 14
            maxZoom: 14
            zoom: 14
            center: [53.34478682683074, -6.256713864687526]
            zoomControl: false
            maxBounds: [[53.243244, -6.458032],[53.422022, -6.037805]]

        @featureGroup = L.featureGroup()
            .addTo(@map)

        @map.on 'draw:created', (e) =>
              @featureGroup.addLayer e.layer

    discardState: ->

        @selected_tweet.protect = false if @selected_tweet
        @selected_tweet = undefined

        @map.removeLayer(t.circle) for t in @api.tweets when t.circle?
        t.soundSource.destroy() for t in @api.tweets when t.circle?

        @api.clearTweets()

        $("#frame").html ""

    drawAtTime: (time) ->

        for t in @api.tweets

            if t.circle?

                if t.protected? and t.protected
                    currentRadius = CIRCLE_RADIUS+Math.abs(Math.cos(6*(time-t.created_at)/(CIRCLE_DECAY/2))*20)
                    weight = Math.abs(Math.cos(8*(time-t.created_at)/(CIRCLE_DECAY/2))*20)

                else
                    currentRadius = -CIRCLE_RADIUS/CIRCLE_DECAY*(time-t.created_at)+CIRCLE_RADIUS
                    weight = Math.abs(Math.cos(4*(time-t.created_at)/(CIRCLE_DECAY/2))*20)

                if currentRadius > 0
                    t.circle.setRadius currentRadius
                    t.circle.setStyle
                        weight: weight
                else
                    @map.removeLayer(t.circle)
                    t.circle = undefined
                    t.soundSource.destroy()


    updateAtTime: (time, complete) ->

        @api.getTweetsBetweenTimes time-HOUR, time, (tweets) =>

            for t in tweets

                unless t.circle?

                    boundedVal = (x) ->

                        Math.floor(Math.min(Math.max(0,x),255))

                    getBlackRGB = (s) ->

                        r = boundedVal( -510 * s + 255 ).toString(16)
                        g = boundedVal(  510 * s - 255 ).toString(16)

                        r = padTo2(r)
                        g = padTo2(g)

                        "##{r}#{g}00"

                    getWhiteRGB = (s) ->

                        r = boundedVal(-510*s + 510)
                        g = boundedVal(510*s)
                        b = Math.min(r,g)

                        r = padTo2(r.toString(16))
                        g = padTo2(g.toString(16))
                        b = padTo2(b.toString(16))

                        "##{r}#{g}#{b}"

                    t.circle = L.circle [t.lat,t.lon], 10,
                        weight: 5
                        stroke: true
                        color: getWhiteRGB(t.sentiment)
                        opacity: 0.4
                        fillColor: getBlackRGB(t.sentiment)
                        fillOpacity: 1.0

                    t.circle.on 'click', =>

                        @selected_tweet.protected = false if @selected_tweet?
                        @selected_tweet = t
                        t.protected = true

                        $("#frame").html ""
                        twttr.widgets.createTweet t.id, document.getElementById('frame'),
                                align: 'center'

                    t.circle.addTo @featureGroup

                    t.soundSource = new SoundSource t.sentiment, @audiolet

                    point = @map.latLngToLayerPoint [t.lat,t.lon]

                    x = point.x/$("#map").width()

                    t.soundSource.setPan x

                    y = point.y/$("#map").height()

                    xDist = Math.abs(x - 0.5)
                    yDist = Math.abs(y - 0.5)
                    console.log "xDist: #{point.x}, yDist: #{$("#map").width()}"
                    t.soundSource.setVolume 1/(1+9*(Math.pow(xDist,2.0)+Math.pow(yDist,2.0)))
                    t.soundSource.trigger

            complete()

mv = new MapView
mv.render()

offset = 0
lastComplete = true
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
        mv.discardState()
        offset = ui.value-startTime

now = -> new Date(startTime + offset)

setInterval ->

    $("#time").text "#{padTo2((now().getHours()).toString())}:#{padTo2(now().getMinutes().toString())}"
    $("#date").text "#{now().getDate()} #{now().getMonth()+1} #{now().getFullYear()}"

    unless pause

        if lastComplete
            lastComplete = false
            mv.updateAtTime now(), ->
                lastComplete = true

        $("#slider").slider('value',now())
        mv.drawAtTime now()

        offset += SPEED/FPMS

        if offset+startTime > endTime
            mv.discardState()
            offset = 0
, 1/FPMS
