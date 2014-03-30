include RequestHelper

module BusFeature

  def extract_params(msg)
      bus_regex = /(\d+)/
      stop_regex = /(\d+|SOTP|NOTP|WETP|EATP)/
      feature_params = Hash.new
      text_splits = msg.split('AT')
      feature_params['bus_nos'] = text_splits[0].scan(bus_regex).map{|s| s[0].to_i}
      if text_splits.length >= 2 and text_splits[1].strip() != ""
          feature_params['stop_id'] = text_splits[1].scan(stop_regex).map{|s| s[0]}[0] 
      end
      return feature_params
  end

  def found_required_features?(feature_params)
      if feature_params.include?('stop_id')
          return true
      end
      return false
  end
   
  def get_arrival_time_from_sms_api(msg="")
      msg = msg.upcase
      logger.info ">>>>>LOG_INFORMATION : Getting schedule information from SMSAPI..."
      txt_contents = []
      feature_params = extract_params(msg)
      logger.info ">>>>>LOG_INFORMATION : Feature Params : #{feature_params}" 
      if found_required_features?(feature_params)
         sms_api_url    = "http://api.smsmybus.com/v1/getarrivals?key=visak&stopID=#{feature_params['stop_id']}"
         json_obj       = do_request(sms_api_url)

	 i=0;	 
         if json_obj.include? "stop"
	  if feature_params['bus_nos'].any?
             for elt in json_obj["stop"]["route"]
                 if feature_params['bus_nos'].include? elt['routeID'].to_i
		    i= i+1
                    txt_contents << "#{elt['routeID']} at #{elt['arrivalTime']}\n "
                 end
             end
	  else
             for elt in json_obj["stop"]["route"]
		    if elt['routeID'] == "W7"
			next
		    end
		    break if i == 10
		    i= i+1
                    txt_contents << "#{elt['routeID']} at #{elt['arrivalTime']}\n"
             end
	  end
	  if i<=0
              txt_contents << "Invalid bus number or given bus(es) not available at this hour."
	  end
         else json_obj.include? "description"
		 if json_obj["description"].include? "No routes found for this stop"
			txt_contents << "Buses not available at this hour."
		 elsif json_obj["description"].include? "Unable to validate the request"
          		logger.info ">>>>>LOG_INFORMATION : ERROR : Unidentfied stop : #{msg}"
          		txt_contents << "Unidentified stop. Please try again with the correct stop-id."
		 end
	 end
      else
          logger.info ">>>>>LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << "Invalid message format. Message format should be:\nBus (bus-numbers) at (stop-id).\nEg. Bus 2 19 at 178"
      end

      return txt_contents
  end

end
