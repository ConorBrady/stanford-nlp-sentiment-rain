
class window.AppView

    constructor: (center, tweetProducer) ->

        L.mapbox.accessToken = 'pk.eyJ1IjoiY29ub3JicmFkeSIsImEiOiJwTHkxcE9nIn0.tQZaXyeR81SGW8XhtmwhPQ'

        @audiolet = new Audiolet

        @map = L.mapbox.map 'map', 'examples.3hqcl3di',
            minZoom: 14
            maxZoom: 14
            zoom: 13
            center: center
            zoomControl: false
        #    maxBounds: [[53.243244, -6.458032],[53.422022, -6.037805]]

        @featureGroup = L.featureGroup()
            .addTo(@map)

        @map.on 'draw:created', (e) =>
              @featureGroup.addLayer e.layer

        @tweetViews = []

        @tweetProducer = tweetProducer
        @tweetProducer.setTweetCallback (t) =>

            tv = new TweetView t, @audiolet, @map, @featureGroup
            @tweetViews.push tv

            tv.circle.on 'click', =>

                ( tv2.unprotect() for tv2 in @tweetViews )
                tv.protect()
                $("#frame").html ""
                avar = twttr.widgets.createTweet t.id, document.getElementById("frame"),
                    align: 'center'

    draw: (time) ->

        @tweetViews = ( t for t in @tweetViews when not t.isDestroyed() )

        t.draw(time) for t in @tweetViews

        for t in _.rest((t for t in @tweetViews when t.hasShown() and not t.isProtected()).reverse(), 5)
            t.silence()

    reset: ->

        ( t.destroy() for t in @tweetViews )
        @tweetViews = []
        @tweetProducer.reset()
        $("#frame").html ""
