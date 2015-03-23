
class window.AppView

    constructor: ->

        L.mapbox.accessToken = 'pk.eyJ1IjoiY29ub3JicmFkeSIsImEiOiJwTHkxcE9nIn0.tQZaXyeR81SGW8XhtmwhPQ'

        @audiolet = new Audiolet

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

        @tweetViews = []

        @tweetProducer = new TweetProducer (t) =>

            tv = new TweetView t, @audiolet, @map, @featureGroup
            @tweetViews.push tv

            tv.circle.on 'click', =>

                ( t.unprotect() for t in @tweetViews )
                tv.protect()
                $("#frame").html ""
                twttr.widgets.createTweet t.id, document.getElementById("frame"),
                    align: 'center'

    draw: (time) ->

        @tweetViews = ( t for t in @tweetViews when not t.isDestroyed() )

        t.draw(time) for t in @tweetViews

        for t in _.rest((t for t in @tweetViews when t.hasShown() and not t.isProtected()).reverse(), 8)
            t.silence()

        if ( t for t in @tweetViews when not t.hasShown() ).length < 5
            @tweetProducer.setCurrentTime time
            @tweetProducer.requestMore()

    discardState: ->

        ( t.destroy() for t in @tweetViews )
        @tweetProducer.reset()
