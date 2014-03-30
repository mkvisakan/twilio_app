require 'open-uri'
require 'json'
include FeaturesHelper
include MessagingHelper
include BusFeature
include DirectionsFeature
include NearbyFeature


class ReceiveTextController < ApplicationController
  def index
    begin
	welcome_text ="Lets get you started with some examples. Text us:\n1. Bus 2 19 at 2717\n2. From skydeck chicago to navy pier by car\n3. Find 3 bars in boston\nFor more details on our features, message: More 1/2/3. Eg. More 2" 


        help_text = "Usage:\n(1) From skydeck chicago to navy pier by car\n(2) Find 3 restaurants near San Francisco\n(3) Bus 2 19 at 2717\n\n Description:\n(1) To get directions, text: \n\"From (from-addr) to (to-addr) by car/bike/walk/public transit\". Mode of transportation is optional, default is public transit.\n(2) To find nearby places, text:\n\"Find (number) (type-of-place) in/near (location)\". Number of places is optional, default is 5, max is 20.\n(3) To get real time bus info for Madison-WI, text:\n\"Bus (bus-numbers) at (stop-id)\""
        msg = params["Body"]
        from_number = params["From"]
        msg = msg.strip().upcase
	
        #log input
        logger.info ">>>>>LOG_INFORMATION : #{from_number} : #{msg}"

        feature_type = FeaturesHelper.identify_request_type(msg) 
    
        if feature_type == BUS_FEATURE
           txt_contents = get_arrival_time_from_sms_api(msg)
        elsif feature_type == DIRECTIONS_FEATURE
           txt_contents = get_directions_from_google_api(msg)
        elsif feature_type == NEARBY_FEATURE
           txt_contents = get_nearby_from_google_api(msg)
	elsif feature_type == HELP_FEATURE
	   txt_contents = ["Hey there! ",welcome_text]
	elsif feature_type == HELLO_FEATURE
	   txt_contents = ["Welcome aboard! ", welcome_text]
	elsif feature_type == MORE_FEATURE
	   txt_contents = get_more_help(msg)
        else
           txt_contents = ["Snap! Invalid format. ", welcome_text]
        end

        send_message(txt_contents, from_number)

    rescue
         logger.info ">>>>>LOG_INFORMATION : CRASH ERROR : #{$!}"
    ensure
        render text: "Thank you! You will receive an SMS shortly with bus timings."
    end

  end

  def get_more_help(msg="")
      txt_contents = []
      msg_contents = msg.split('MORE')[1].strip()
      msg_contents = msg_contents.split()[0][/\d+/]
      number =msg_contents.to_i
      if number == 1
	txt_contents << "Supported formats for real-time bus info for Madison:\n1. Bus 15 10 at 178 - Timings for buses 15 & 10 at stop-id 178\n2. Bus at 2146 - Timings for the next 10 buses at stop-id 2146"
      elsif number ==2 
	txt_contents << "To get directions, text:\nFrom (location) to (location) by bike/car/walk.\nEg.1. From 154 Buchanan street sfo to market street by bike\n2. From Grand street brooklyn to 6 Avenue Manhattan. Default is public-transit if mode of transportation is not specified." 
      elsif number ==3
	txt_contents << "To find places nearby, text:\nFind (number) (type of place) in/near (location/zipcode).Eg.\n1. Find 3 bars near 21 N Park street Madison WI\n2. Find 2 hair cuts in 98006\n3. Find parking near central park. Default number of results is 5 if not specified."
      else
	 if msg_contents.nil?
		txt_contents << "Oops! Invalid format. For more details on our features, message: More 1/2/3. Eg. More 2" 
	 else
		txt_contents << "Uh-oh! Currently we support only 3 features. Watch out for more!"
	 end
      end
      return txt_contents
  end

end
