require 'generic_api_client'

class UssdAuthClient < GenericAPIClient
    
  def self.terminate_session(sid,response="OK")     
     body = %Q(
        {
          "ussdSessionTerminationParameters" : {
            "outboundUSSDTextMessage" : {
              "message" : "#{response}"
            }
          }
        }
     )

     Rails.logger.debug("UssdAuthClient terminate request #{body}")
     response = post( "/#{sid}/terminate",body)     
     Rails.logger.debug("UssdAuthClient terminate response #{response}")   
  end
  
  def self.authenticate(params)
     body = %Q(
      {
        "ussdSessionCreationParameters" : {
          "ussdSessionInformation" : {
            "destinationAddress" : "#{params[:msisdn]}",
            "senderAddress" : "UssdAuth"
          },
          "outboundSessionMessageRequest" : {
            "outboundUSSDTextMessage" : {
              "message" : "#{params[:challenge]}",
              "responseProvided" : true
            }
          }
        }
      }
     )
     Rails.logger.debug("UssdAuthClient authenticate request #{body}")
     response = post( "",body)    
     Rails.logger.debug("UssdAuthClient authenticate response #{response}")      
     
     if not response.nil?
        sid=response["ussdSessionCreationParameters"]["ussdSessionInformation"]["ussdSessionIdentifier"]
        user_input=response["ussdSessionCreationParameters"]["outboundSessionMessageRequest"]["outboundUSSDTextMessage"]["response"]
     else 
        user_input=nil
     end
     res=( params[:expect] == user_input )
     if not response.nil?
      if res
        terminate_session sid, params[:response_ok]
      else
        terminate_session sid, params[:response_cancel]
      end
     end
     Rails.logger.debug("UssdAuthClient authenticate: #{res}")
     return res  
  end
  
end
