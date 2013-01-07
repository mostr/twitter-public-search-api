require "rspec"
require 'tweets_reader'
require 'fake_web'
require 'json'

module Twitter

  describe TweetsReader do

    before(:all) do
      @url = TweetsReader::URL + 'q=code&result_type=recent'
      FakeWeb.allow_net_connect = false
      @fake_responses = prepare_fake_responses
    end

    before(:each) do
      FakeWeb.clean_registry
      @query = 'code'
    end



    it "should return array of tweets hashes from one page" do
      FakeWeb.register_uri(:get, @url, :body => @fake_responses[:standard_response][:raw_content])
      FakeWeb.register_uri(:get, "#{@url}&max_id=288373232690687999", :body => @fake_responses[:empty_results_response][:raw_content])

      reader = TweetsReader.new(@query)
      tweets = reader.find_recent

      tweets.should == @fake_responses[:standard_response][:tweets]
    end



    it "should return empty array when no results returned on first page" do
      FakeWeb.register_uri(:get, @url, :body => @fake_responses[:empty_results_response][:raw_content])

      reader = TweetsReader.new(@query)
      tweets = reader.find_recent

      tweets.should be_empty
    end



    it "should collect tweets from next page with correct max_id query param" do
      FakeWeb.register_uri(:get, "#{@url}", :body => @fake_responses[:multi_paged_response_1][:raw_content])
      FakeWeb.register_uri(:get, "#{@url}&max_id=288217277147533311", :body => @fake_responses[:multi_paged_response_2][:raw_content])
      FakeWeb.register_uri(:get, "#{@url}&max_id=287941375293542400", :body => @fake_responses[:empty_results_response][:raw_content])

      reader = TweetsReader.new(@query)
      tweets = reader.find_recent

      tweets_count = @fake_responses[:multi_paged_response_1][:tweets_no] + @fake_responses[:multi_paged_response_2][:tweets_no]
      tweets.size.should == tweets_count
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