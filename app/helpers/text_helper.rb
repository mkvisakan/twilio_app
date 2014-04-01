module TextHelper

  WELCOME_TXT ="Howdy\n" \
	       "Welcome to TextMe!\n" \
	       "Txt us what u want, we'll get it 2 u asap!\n" \
               "Usage:\n" \
               "1. Bus directions (in Madison)? Bus 2 19 at 2717\n" \
               "2. Driving directions? From skydeck chicago to navy pier by car\n" \
               "3. Nearby places? Find 3 bars in boston\n" \
               "To view more usage formats in each feature, txt 'More feature-number'; Ex: 'More 1' for Bus Directions!"

  THANK_YOU = "Thank you! We will get back to you shortly with the information!"
  
  #Example Usage Format : 
  BUS_USAGE_FORMAT =    "Supported formats for real-time bus info for Madison:\n" \
			"1. Bus 15 10 at 178 - Timings for buses 15 & 10 at stop-id 178\n" \
			"2. Bus at 2146 - Timings for the next 10 buses at stop-id 2146"

  DRIVING_USAGE_FORMAT =   "To get directions, text:\n" \
			   "From (location) to (location) by bike/car/walk.\n" \
			   "1. From 154 Buchanan street sfo to market street by bike\n" \
			   "2. From Grand street brooklyn to 6 Avenue Manhattan. Default is public-transit if mode of transportation is not specified."

  PLACES_USAGE_FORMAT = "To find places nearby, text:\n" \
			"Find (number) (type of place) in/near (location/zipcode).Eg.\n" \
			"1. Find 3 bars near 21 N Park street Madison WI\n" \
			"2. Find 2 hair cuts in 98006\n" \
			"3. Find parking near central park. Default number of results is 5 if not specified."

  INVALID_MORE_MSG_FORMAT_1 = "Invalid format.\n" \
		   	      "To view more usage formats in each feature, txt 'More feature-number'; Ex: 'More 1' for Bus Directions!"
 
  INVALID_MORE_MSG_FORMAT_2 = "Uh-oh! Currently we support only 3 features. Watch out for more!"
 
  RESULTS_NOT_FOUND = "Results not found."
  
  ROUTES_NOT_FOUND = "Routes not found."
 
  UNIDENT_LOC = "Unidentified source/destination location. Please try again with city/state information."

  INVALID_FORMAT_DIRECTIONS = "Invalid format. Usage:\nFrom (from-addr) to (to-addr) by car/bus/bike/walk.\nEg. From skydeck chicago to navy pier by car"

  INVALID_FORMAT_BUS = "Invalid format. Message format should be:\nBus (bus-numbers) at (stop-id).\nEg. Bus 2 19 at 178"
 
  def welcome_text()
      return WELCOME_TXT 
  end

  def thank_you()
      return THANK_YOU
  end

  def get_more_msg(feature_num)
     if feature_num == 1
	return BUS_USAGE_FORMAT
     elsif feature_num == 2
	return DRIVING_USAGE_FORMAT
     elsif feature_num == 3
	return PLACES_USAGE_FORMAT
     elsif feature_num == 4
	return INVALID_MORE_MSG_FORMAT_1
     elsif feature_num == 5
	return INVALID_MORE_MSG_FORMAT_2 
     end
  end
  
  def get_url_nearby(msg_contents)
	api_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{msg_contents}&sensor=true&opennow&key=AIzaSyDvHC2dZhR9I0uMBtLxp0Bq1qulebuTRQY"
	return api_url
  end    	
	
  def get_url_directions(from_address, to_address, default_mode, dept_time)
	api_url = "https://maps.googleapis.com/maps/api/directions/json?origin=#{from_address}&destination=#{to_address}&sensor=false&key=AIzaSyBYx4aypBnysn1OgzxR26ITEoPD0I60ugc&mode=#{default_mode}&departure_time=#{dept_time}"
	return api_url
  end
 
  def get_url_sms(stop_id)
	sms_url = "http://api.smsmybus.com/v1/getarrivals?key=bontrager&stopID=#{stop_id}"
  end
  
  def get_results_not_found()
	return RESULTS_NOT_FOUND
  end
  
  def get_routes_not_found()
	return ROUTES_NOT_FOUND
  end

  def get_unident_loc()
	return UNIDENT_LOC
  end

  def get_invalid_format(type)
	if type == "directions"
		return INVALID_FORMAT_DIRECTIONS
	elsif type == "bus"
		return INVALID_FORMAT_BUS 
  	end
  end
end


