require 'open-uri'
require 'json'

module Twitter

  class Search

    URL = 'http://search.twitter.com/search.json?'.freeze
    DEFAULTS = {:result_type => 'recent', :rpp => 100}.freeze

    def initialize(query)
      @params = DEFAULTS.merge({:q => query})
    end

    def find_recent
      tweets = Array.new
      loop {
        url = next_request_url
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

    def next_request_url
      URL + URI.encode_www_form(@params)
    end

  end

end