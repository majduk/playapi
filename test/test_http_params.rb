require 'minitest/autorun'
require 'generic_api_client'

class HttpParamsTest < Minitest::Test
   
    def test_timeouts
      GenericAPIClient.const_set(:APP_CONFIG, {
        :generic_api_client =>{           
          :appkey => "appkey",
          :uri => "/uri"
        }
      } )
      GenericAPIClient.execute(:post,"/path") 
    end

end
