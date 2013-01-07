require 'open-uri'
require 'json'

module Twitter

  class TweetsReader

    URL = 'http://search.twitter.com/search.json?'

    def initialize(query)
      @params = Hash.new
      @params[:q] = query
      @params[:result_type] = 'recent'
    end

    def find_recent
      tweets = Array.new
      loop {
        url = request_url
        puts "reading from #{url}"
        response = JSON.parse(open(url).read)
        break if no_tweets_in(response)
        udpate_query_params(response)
        tweets = tweets + response["results"]
      }
      tweets
    end

    private

    def no_tweets_in(response)
      response["results"].empty?
    end

    def udpate_query_params(response)
      @params[:max_id] = response["results"].last["id"].to_i - 1 unless response["results"].empty?
    end

    def request_url
      URL + URI.encode_www_form(@params)
    end

  end

end