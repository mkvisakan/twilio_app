include RequestHelper
include TextHelper

module BusFeature

  def extract_bus_params(msg)
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

  def found_required_bus_params?(feature_params)
      if feature_params.include?('stop_id')
          return true
      end
      return false
  end
   
  def get_arrival_time_from_sms_api(msg="")
      msg = msg.upcase
      logger.info ">>>>>TEXTME_LOG_INFORMATION : Getting schedule information from SMSAPI..."
      txt_contents = []
      feature_params = extract_bus_params(msg)
      logger.info ">>>>>TEXTME_LOG_INFORMATION : Feature Params : #{feature_params}" 
      #invalid bus nos taken from https://www.cityofmadison.com/metro/schedules/schedules.cfm
      invalid_bus_nos = [9,23,24,41,42,43,45,46,49,53,54,60,61,62,64,65,66,69,76,77,79,83]
      
      if found_required_bus_params?(feature_params)
         sms_api_url    = TextHelper.get_url_sms(feature_params['stop_id'])
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
		invalid_bus= bus_nos & invalid_bus_nos
                if invalid_bus.empty?
                        range = 1...84
                        if (bus_nos & range.to_a).present?
                                txt_contents << "Shoot! Bus not available at this hour. Need direction to some place? Text 'More 2'."
                        else
                                txt_contents << "Snap! Can't find routes. Check your bus number, may be?"
                        end
                else
                         txt_contents << "Snap! Can't find routes. Check your bus number, may be?"
                end
          end

         else json_obj.include? "description"
		 if json_obj["description"].include? "No routes found for this stop"
			txt_contents << "Shoot! Bus not available at this hour. Need direction to some place? Text 'More 2'"
		 elsif json_obj["description"].include? "Unable to validate the request"
          		logger.info ">>>>>TEXTME_LOG_INFORMATION : ERROR : Unidentfied stop : #{msg}"
          		txt_contents << "Unidentified stop. Please try again with the correct stop-id."
		 end
	 end
      else
          logger.info ">>>>>TEXTME_LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << TextHelper.get_invalid_format(bus)
      end

      return txt_contents
  end

end
