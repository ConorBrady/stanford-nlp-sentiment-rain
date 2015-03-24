
padTo2 = (s) ->
    return s unless s.length is 1
    return "0"+s if s.length is 1

boundedVal = (x,min,max) ->

    Math.floor(Math.min(Math.max(min,x),max))

getBlackRGB = (s) ->

    r = boundedVal( -510 * s + 255, 0, 255).toString(16)
    g = boundedVal(  510 * s - 255, 0, 255).toString(16)

    r = padTo2(r)
    g = padTo2(g)

    "##{r}#{g}00"

getWhiteRGB = (s) ->

    r = boundedVal(-510*s + 510, 0, 255)
    g = boundedVal(510*s, 0, 255)
    b = Math.min(r,g)

    r = padTo2(r.toString(16))
    g = padTo2(g.toString(16))
    b = padTo2(b.toString(16))

    "##{r}#{g}#{b}"


class window.TweetView

    constructor: (tweet, audiolet, map, featureGroup) ->

        @shown = false
        @protected = false
        @destroyed = false
        @observers = {}
        @t = tweet
        @map = map
        @featureGroup = featureGroup
        @audiolet = audiolet
        @soundSource = undefined

        @circle = L.circle [@t.lat,@t.lon], 10,
            weight: 5
            stroke: true
            color: getWhiteRGB(@t.sentiment)
            opacity: 0.4
            fillColor: getBlackRGB(@t.sentiment)
            fillOpacity: 1.0

    protect: -> @protected = true

    unprotect: -> @protected = false

    isProtected: -> @protected

    draw: (time) ->

        if time > @t.created_at

            @_show() unless @shown || not @_inView()

            unless @destroyed

                if @protected

                    currentRadius = CIRCLE_RADIUS+Math.abs(Math.cos(6*(time-@t.created_at)/(CIRCLE_DECAY/2))*20)
                    weight = Math.abs(Math.cos(8*(time-@t.created_at)/(CIRCLE_DECAY/2))*20)

                else
                    currentRadius = -CIRCLE_RADIUS/CIRCLE_DECAY*(time-@t.created_at)+CIRCLE_RADIUS
                    weight = Math.abs(Math.cos(4*(time-@t.created_at)/(CIRCLE_DECAY/2))*20)

                @circle.setRadius currentRadius
                @circle.setStyle
                    weight: weight

                @destroy() if currentRadius < 0
        @

    hasShown: -> @shown

    isDestroyed: -> @destroyed

    _inView: ->

        point = @map.latLngToLayerPoint [@t.lat,@t.lon]
        size = @map.getSize()

        x = point.x/size.x
        y = point.y/size.y

        x > 0 and x < 1 and y > 0 and y < 1


    _show: ->

        @soundSource = new SoundSource @t.sentiment, @audiolet

        point = @map.latLngToLayerPoint [@t.lat,@t.lon]
        size = @map.getSize()

        x = point.x/size.x
        y = point.y/size.y

        @soundSource.setPan x

        f = (x) -> Math.pow( x - 0.5, 2 )
        @soundSource.setVolume 1/(1+9*(f(x)+f(y)))

        @circle.addTo @featureGroup

        @shown = true

    destroy: ->

        @map.removeLayer @circle
        @soundSource.destroy() if @soundSource?
        @destroyed = true

    silence: ->

        @soundSource.destroy() if @soundSource?
