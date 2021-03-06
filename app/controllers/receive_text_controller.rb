require 'open-uri'
require 'json'
include FeaturesHelper
include MessagingHelper
include BusFeature
include TextHelper
include DirectionsFeature
include NearbyFeature
include FunFeature

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
		if (msg =~ /BUS(.*)AT (\d+|SOTP|NOTP|WETP|EATP)$/)
			txt_contents = get_arrival_time_from_sms_api(msg)
		else

                        txt_contents  =get_bus_stopid_by_street_name(msg)
        		logger.info ">>>>>LOG_INFORMATION : #{txt_contents}"
		end
        elsif feature_type == DIRECTIONS_FEATURE
           txt_contents = get_directions_from_google_api(msg, params)
        elsif feature_type == NEARBY_FEATURE
           txt_contents = get_nearby_from_google_api(msg)
	elsif feature_type == HELP_FEATURE
	   txt_contents = ["Howdy! Lets get you started. ",welcome_text]
	elsif feature_type == HELLO_FEATURE
	   txt_contents = ["Hey there! Lets get you started. ", welcome_text]
	elsif feature_type == MORE_FEATURE
	   txt_contents = get_more_help(msg)
	elsif feature_type == FUN_FEATURE
	   txt_contents = get_fun_message(msg)
        else
           txt_contents = ["Snap! Can't recognize. ", welcome_text]
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
      msg_contents = msg.split('MORE')[1]
      if msg_contents.nil? 
		txt_contents << TextHelper.get_more_msg(4)
		return txt_contents
      end 
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
