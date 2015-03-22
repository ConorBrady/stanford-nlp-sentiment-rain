require 'net/http'
require 'json'
require 'open-uri'
require 'time'

get '/' do
    haml :index, format: :html5
end

class NilClass

  def missing_method(*_)
    nil
  end

  def respond_to_missing?(*_)
    true
  end

end

get '/tweets' do

    content_type :json

    query  = "select id, coordinates, text, created "
    query += "from DublinMarathon "
    query += "where text.language='en' and coordinates is not null and created > '#{ Time.at(params[:since].to_i/1000).to_s || 0 }' "
    query += "order by created asc"

    url = URI.parse("http://graisearch.scss.tcd.ie/query/Graisearch/sql/#{ URI::encode(query) }/#{ params[:limit] || 20 }/*:1")

    req = Net::HTTP::Get.new(url.to_s)
    req.basic_auth('conor','conorjbrady1@gmail.com')

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
