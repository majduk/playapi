require 'generic_api_client'

class UssdAuthClient < GenericAPIClient
  
  class Error < StandardError
  end  
  class Timeout < Error
  end  

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
     destination_address=params[:msisdn]
     raise ArgumentError.new("UssdAuthClient msisdn missing") if destination_address.nil? 
     challenge_message=params[:challenge]
     raise ArgumentError.new("UssdAuthClient challenge text missing") if challenge_message.nil?
     raise ArgumentError.new("UssdAuthClient expected text missing") if params[:expect].nil?
     if challenge_message.length > 160
       Rails.logger.warn("UssdAuthClient challenge_message too long, triming: #{challenge_message}")
       challenge_message=challenge_message[0,160]
     end      
     body = %Q(
      {
        "ussdSessionCreationParameters" : {
          "ussdSessionInformation" : {
            "destinationAddress" : "#{destination_address}",
            "senderAddress" : "UssdAuth"
          },
          "outboundSessionMessageRequest" : {
            "outboundUSSDTextMessage" : {
              "message" : "#{challenge_message}",
              "responseProvided" : true
            }
          }
        }
      }
     )
    begin
        Rails.logger.debug("UssdAuthClient authenticate request #{body}")
        response = post( "",body) do |request,resp|
          raise_exception_on_error(resp)
        end   
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
    rescue HTTPResponseException => e
        Rails.logger.debug("UssdAuthClient authenticate error #{e.inspect}")
        raise Error.new
    rescue Net::ReadTimeout    
        Rails.logger.debug("UssdAuthClient authenticate timeout")
        raise Timeout.new
    end
  end
  
end
