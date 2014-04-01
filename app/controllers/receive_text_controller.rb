require 'open-uri'
require 'json'
include FeaturesHelper
include MessagingHelper
include BusFeature
include TextHelper
include DirectionsFeature
include NearbyFeature


class ReceiveTextController < ApplicationController
  def index
    begin
	welcome_text = TextHelper.welcome_text()

        msg = params["Body"]
        from_number = params["From"]
        msg = msg.strip().upcase
	
        #log input
        logger.info ">>>>>TEXTME_LOG_INFORMATION : #{from_number} : #{msg}"

        feature_type = FeaturesHelper.identify_request_type(msg) 
    
        if feature_type == BUS_FEATURE
           txt_contents = get_arrival_time_from_sms_api(msg)
        elsif feature_type == DIRECTIONS_FEATURE
           txt_contents = get_directions_from_google_api(msg, params)
        elsif feature_type == NEARBY_FEATURE
           txt_contents = get_nearby_from_google_api(msg)
	elsif feature_type == HELP_FEATURE
	   txt_contents = ["Hey there! ",welcome_text]
	elsif feature_type == HELLO_FEATURE
	   txt_contents = [welcome_text]
	elsif feature_type == MORE_FEATURE
	   txt_contents = get_more_help(msg)
        else
           txt_contents = ["Invalid format. ", welcome_text]
        end

        send_message(txt_contents, from_number)

    rescue
         logger.info ">>>>>TEXTME_LOG_INFORMATION : CRASH ERROR : #{$!}"
    ensure
        render text: TextHelper.thank_you()
    end

  end

  def get_more_help(msg="")
      txt_contents = []
      msg_contents = msg.split('MORE')[1].strip()
      msg_contents = msg_contents.split()[0][/\d+/]
      number = msg_contents.to_i
      if number == 1
	txt_contents << TextHelper.get_more_msg(1) 
      elsif number ==2 
	txt_contents << TextHelper.get_more_msg(2) 
      elsif number ==3
	txt_contents << TextHelper.get_more_msg(3) 
      else
	 if msg_contents.nil?
		txt_contents << TextHelper.get_more_msg(4) 
	 else
		txt_contents << TextHelper.get_more_msg(5)
	 end
      end
      return txt_contents
  end

end
