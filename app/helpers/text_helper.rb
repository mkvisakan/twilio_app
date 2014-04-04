module TextHelper

  WELCOME_TXT ="Text us:\n" \
               "1. Bus 2 at 178 (for real-time bus info in Madison)\n" \
               "2. From skydeck chicago to navy pier by car (for directions)\n" \
               "3. Find 3 bars in boston (for nearby places)\n" \
               "For more details, text 'More #feature'. E.g., 'More 2' for directions"

  THANK_YOU = "Thank you! We will get back to you shortly with the information!"
  
  #Example Usage Format : 
  BUS_USAGE_FORMAT =   "To get real-time bus info in Madison, WI, text:\n" \
			   "Bus (bus#) at (stop-id). Examples:\n" \
			   "1. Bus 3 8 at 178 - info for buses 3 & 8 at stop-id 178\n" \
			   "2. Bus at 2146 - info for the next 10 buses at stop-id 2146."

  DRIVING_USAGE_FORMAT =   "To get Google directions, text:\n" \
			   "From (location) to (location) by bike/car/walk. Examples:\n" \
			   "1. From 154 Buchanan street sfo to market street by bike\n" \
			   "2. From Grand street brooklyn to 6 Avenue Manhattan. Default is public-transit if mode of transportation is not specified."

  PLACES_USAGE_FORMAT = "To find places nearby, text:\n" \
			"Find (number) (type of place) in/near (location/zipcode). Examples:\n" \
			"1. Find 3 bars near 21 N Park street Madison WI\n" \
			"2. Find 2 hair cuts in 98006\n" \
			"3. Find parking near central park. Default number of results is 5 if not specified."

  INVALID_MORE_MSG_FORMAT_1 = "Dagnabbit! Can't recognize. Wanna know more about us? Text:\n1. More 1 for real-time bus info\n2. More 2 for Google directions\n3. More 3 for nearby places"
 
  INVALID_MORE_MSG_FORMAT_2 = "Uh-oh! Currently we support only 3 features. Watch out for more!"
 
  RESULTS_NOT_FOUND = "Oops! Results not found."
  
  ROUTES_NOT_FOUND = "Uh-oh! Routes not found."
 
  UNIDENT_LOC = "Unidentified source/destination location. Please try again with city/state information."

  INVALID_FORMAT_DIRECTIONS = "Shoot! Can't recognize. Usage:\nFrom (from-addr) to (to-addr) by car/bus/bike/walk.\nEg. From skydeck chicago to navy pier by car"

  INVALID_FORMAT_BUS = "Snap! Can't recognize. Usage:\nBus (bus-numbers) at (stop-id). Eg. Bus 2 19 at 178 or Bus at 178"
 
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
	sms_url = "http://api.smsmybus.com/v1/getarrivals?key=visak&stopID=#{stop_id}"
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


