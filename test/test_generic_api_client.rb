require 'minitest/autorun'
require 'generic_api_client'
require 'uri'
require 'commons'

class GenericAPIClientTest < Minitest::Test

    def setup
      TestSuiteConfig.load
    end

    def test_timeout
      Net::HTTP.trigger_timeout=true
      assert_raises(Net::ReadTimeout) {
        GenericAPIClient.execute(:post,"/path") 
      }
      assert_equal "/uri/path?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_success_post
      response={"param"=>"value"}
      Net::HTTP.respond_ok response.to_json
      assert_equal response, GenericAPIClient.execute(:post,"/path") 
      assert_equal "/uri/path?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_success_get_w_params
      response={"param"=>"value"}
      query_params={"param1"=>"value1","param2"=>"value2"}
      Net::HTTP.respond_ok response.to_json
      assert_equal response, GenericAPIClient.execute(:get,"/path",query_params) 
      assert_equal "/uri/path?resformat=json&param1=value1&param2=value2&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_internal_error_no_body
      Net::HTTP.respond_internal_error
      assert_nil GenericAPIClient.execute(:post,"/path") 
      assert_equal "/uri/path?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_internal_error
      response={"param"=>"value"}
      Net::HTTP.respond_internal_error response.to_json
      assert_nil GenericAPIClient.execute(:post,"/path") 
      assert_equal "/uri/path?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

end
