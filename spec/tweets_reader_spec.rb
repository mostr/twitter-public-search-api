require "rspec"
require 'tweets_reader'
require 'fake_web'
require 'json'

module Twitter

  describe Search do

    before(:all) do
      FakeWeb.allow_net_connect = false
      @fake_responses = prepare_fake_responses
      @query = 'code'
      @url = Search::URL + URI.encode_www_form(Search::DEFAULTS.merge({:q => @query}))
    end

    before(:each) do
      FakeWeb.clean_registry
    end



    it "should return array of tweets hashes from one page" do
      standard_response = @fake_responses[:standard_response]
      empty_response = @fake_responses[:empty_results_response]
      FakeWeb.register_uri(:get, @url, :body => standard_response[:raw_content])
      FakeWeb.register_uri(:get, request_url({:q => @query, :max_id => standard_response[:next_max_id]}), :body => empty_response[:raw_content])

      reader = Search.new(@query)
      tweets = reader.find_recent

      tweets.should == @fake_responses[:standard_response][:tweets]
    end



    it "should return empty array when no results returned on first page" do
      empty_response = @fake_responses[:empty_results_response]
      FakeWeb.register_uri(:get, @url, :body => empty_response[:raw_content])

      reader = Search.new(@query)
      tweets = reader.find_recent

      tweets.should be_empty
    end



    it "should collect tweets from next page with correct max_id query param" do
      page_one_response = @fake_responses[:multi_paged_response_1]
      page_two_response = @fake_responses[:multi_paged_response_2]
      empty_response = @fake_responses[:empty_results_response]
      FakeWeb.register_uri(:get, request_url({:q => @query}), :body => page_one_response[:raw_content])
      FakeWeb.register_uri(:get, request_url({:q => @query, :max_id => page_one_response[:next_max_id]}), :body => page_two_response[:raw_content])
      FakeWeb.register_uri(:get, request_url({:q => @query, :max_id => page_two_response[:next_max_id]}), :body => empty_response[:raw_content])

      reader = Search.new(@query)
      tweets = reader.find_recent

      tweets_count = page_one_response[:tweets_no] + page_two_response[:tweets_no]
      tweets.size.should == tweets_count
    end

    def request_url(options)
      Search::URL + URI.encode_www_form(Search::DEFAULTS.merge(options))
    end

    def prepare_fake_responses
      responses = {}
      ['standard_response', 'multi_paged_response_1', 'multi_paged_response_2', 'empty_results_response'].map do |response_file|
        raw_content = File.read(File.expand_path("../test_data/#{response_file}.json", __FILE__))
        json_content = JSON.parse(raw_content)
        responses[response_file.to_sym] =
            {
              :tweets => json_content["results"],
              :tweets_no => json_content["results"].size,
              :next_max_id => (json_content["results"].last["id"].to_i - 1 unless json_content["results"].empty?),
              :raw_content => raw_content
            }
      end
      responses
    end

  end

end