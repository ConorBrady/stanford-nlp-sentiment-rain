require 'net/http'
require 'json'
require 'open-uri'
require 'time'
require 'logger'

log = Logger.new(STDOUT)

get '/' do
    redirect '/scenario'
end

get '/scenario' do
    haml :scenario, format: :html5
end

get '/live' do
    haml :live, format: :html5
end

get '/live_tweets' do


    client = Twitter::REST::Client.new do |config|
        config.consumer_key        = ENV["SENTIMENT_RAIN_TW_KEY"]
        config.consumer_secret     = ENV["SENTIMENT_RAIN_TW_SECRET"]
    end

    content_type :json

    unless params[:since]
        status 400
        return { 'error' => ":since parameter missing" }.to_json
    end

    puts "Requesting from Twitter"
    data = client.search("",
            geocode: "37.777222,-122.411111,4km",
            lang: 'en',
            result_type: 'recent' )
        .take_while { |t| (t.created_at.to_i*1000).to_s > params[:since] }
        .collect do |tweet|
        puts "Recieved a tweet #{tweet.text}"
        y = {}

        y['id'] = /\/(\d+)$/.match(tweet.url.to_s)[1]
        y['lat']  = tweet.geo.lat
        y['lon']  = tweet.geo.lng

        y['text'] = tweet.text
        y['link'] = tweet.url

        y['created_at'] = (tweet.created_at.to_i*1000).to_s
        y['created_at_readable'] = tweet.created_at
        y
    end

    puts "Tweets recieved"
    data.reverse!.select! { |d| not d['lat'].nil? }

    BATCH_SIZE = 10
    (0..data.length/BATCH_SIZE).each do |i|
        _get_sentiment( data[i*BATCH_SIZE,BATCH_SIZE].map { |x| x['text'] } ).map.with_index { |x,j| data[i*BATCH_SIZE+j]['sentiment'] = x }
    end

    response = {}
    response['data'] = data

    return response.to_json

end

get '/scenario_tweets' do

    content_type :json
    cache_control :public, :max_age => 7200

    query  = "select id, coordinates, text, created "
    query += "from DublinMarathon "
    query += "where text.language='en' and coordinates is not null and created > '#{ Time.at(params[:since].to_i/1000).to_s || 0 }' "
    query += "order by created asc"

    url = URI.parse("http://graisearch.scss.tcd.ie/query/Graisearch/sql/#{ URI::encode(query) }/#{ params[:limit] || 20 }/*:1")

    req = Net::HTTP::Get.new(url.to_s)
    req.basic_auth(ENV["GRAISEARCH_USERNAME"],ENV["GRAISEARCH_PASSWORD"])

    res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
    end

    db = JSON.parse(res.body)

    data = []

    db['result'].each do |x|

        y = {}

        y['id'] = x['id']
        y['lat']  = x['coordinates']['latitude']
        y['lon']  = x['coordinates']['longitude']
        matches = /(.*)(http[s]?:\/\/t.co\/\w+).*/.match(x['text']['message'])
        unless matches.nil?
            y['text'] = matches[1]
            y['link'] = matches[2]
        else
            y['text'] = x['text']['message']
            y['link'] = nil
        end
        y['created_at'] = (Time.parse(x['created']).to_i*1000).to_s

        data << y

    end

    response = {}

    _get_sentiment( data.map { |x| x['text'] } ).map.with_index { |x,i| data[i]['sentiment'] = x }

    response[:data] = data
    response[:paging] = {}
    response[:paging][:next] = "#{/([^?]+).*/.match(request.url)[1]}?limit=#{ params[:limit] || 20 }&since=#{ URI::encode(data.last['created_at']) }"

    return response.to_json
end

def _get_sentiment(lines)

    url = URI.parse("http://stanford-nlp.conorbrady.com/sentiment?lines=#{ lines.map { |l| URI::encode(l) }.join('&lines=') }")

    request = Net::HTTP::Get.new(url.to_s)
    request.basic_auth('conor','conorjbrady1@gmail.com')

    res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(request)
    end

    data = JSON.parse(res.body).values

    return data.map { |x| x['sentiment'] }

end
