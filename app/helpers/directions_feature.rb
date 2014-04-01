module DirectionsFeature

  def extract_direction_params(msg)
      dir_regex      = /FROM *(.*) *TO *(.*) */
      dir_mode_regex = /FROM *(.*) *TO *(.*) *BY *(.*) */
      feature_params = Hash.new
      data_list      = msg.scan(dir_mode_regex)
      if !data_list.any?
          data_list = msg.scan(dir_regex)
      end
      if data_list.any? and data_list[0].length >= 2
          feature_params['from_address'] = data_list[0][0].strip()
          feature_params['to_address']   = data_list[0][1].strip()
          if data_list[0].length >= 3
              feature_params['user_mode'] = data_list[0][2].strip()
          end
      end
      return feature_params
  end

  def found_required_direction_params?(feature_params)
      if feature_params.include?('from_address') and feature_params.include?('to_address')
          return true
      end
      return false
  end

  def fetch_transit_mode(feature_params)
      default_mode = "transit"
      if feature_params.include?('user_mode')
          user_mode    = feature_params['user_mode'] 
	  if user_mode.include? "CAR"
	      default_mode = "driving"
	  elsif user_mode.include? "BIKE"
	      default_mode = "bicycling"
	  elsif user_mode.include? "WALK"
	      default_mode = "walking"
	  end
      end
      logger.info ">>>>>LOG_INFORMATION : transit mode : #{default_mode}"
      return default_mode
  end

  def get_transit_instructions(transit_node)
      count = 0
      txt_contents = []
      for elt in transit_node
          if elt["travel_mode"] == "TRANSIT"	
              count=count+1
              txt_contents << "(#{count}) Take #{elt['transit_details']['line']['short_name']} #{elt['html_instructions']} at #{elt['transit_details']['departure_time']['text']}. "
              txt_contents << "Get down at #{elt['transit_details']['arrival_stop']['name']} at #{elt['transit_details']['arrival_time']['text']}\n"
          elsif elt["travel_mode"] == "WALKING"
	      count=count+1
              walk_content = elt['html_instructions']
	      if walk_content.include?(", USA")
	          walk_content = walk_content.split(', USA')[0]
	      end
              txt_contents << "(#{count}) #{walk_content}\n" #{elt['html_instructions']}\n"
          end
      end
      return txt_contents
  end

  def get_driving_instructions(driving_node)
      count = 0
      txt_contents = []
      for elt in driving_node
          count      = count+1
          d_inst     = elt['html_instructions']
          d_stripped = d_inst.gsub('<b>','')
          d_stripped = d_stripped.gsub('</b>','')
          d_stripped = d_stripped.gsub('</div>','.')
          d_stripped = d_stripped.gsub(/<.*">/,'. ')
          d_stripped = d_stripped.gsub('&nbsp;','')
          distance   = elt['distance']['text'];
          if d_stripped.downcase.start_with?('head') or d_stripped.downcase.start_with?('continue')
              txt_contents << "\n(#{count}) #{d_stripped} for #{distance}."
	  else
              txt_contents << "\n(#{count}) #{d_stripped}. Stay for #{distance}."
	  end
      end
      if d_stripped.downcase.start_with?('head') or d_stripped.downcase.start_with?('continue')
          txt_contents.pop	
          txt_contents << "\n(#{count}) #{d_stripped}"
      else
          txt_contents.pop	
          txt_contents << "\n(#{count}) #{d_stripped}"
      end
      txt_contents << ". In #{distance}, you will arrive at your destination."
      return txt_contents
  end

  def get_instructions(json_obj, default_mode)
      txt_contents = []
      if json_obj.include?("routes") && json_obj["routes"].any?
          if default_mode.include?("transit")
              txt_contents = get_transit_instructions(json_obj["routes"][0]["legs"][0]["steps"])
	  else
              txt_contents = get_driving_instructions(json_obj["routes"][0]["legs"][0]["steps"])
	  end
      else
          logger.info ">>>>>LOG_INFORMATION : 'Routes not found in json result: #{msg}"
	  txt_contents << "Routes not found."	
      end
      return txt_contents
  end

  def get_directions_from_google_api(msg="", params={})
      msg = msg.upcase
      logger.info ">>>>>LOG_INFORMATION : Getting directions from google API..."
      txt_contents = []
      feature_params = extract_direction_params(msg)
      logger.info ">>>>>LOG_INFORMATION : Feature Params : #{feature_params}" 
      if found_required_direction_params?(feature_params)

          default_mode = fetch_transit_mode(feature_params)
          google_api_url = "https://maps.googleapis.com/maps/api/directions/json?origin=#{feature_params['from_address']}&destination=#{feature_params['to_address']}&sensor=false&key=AIzaSyBYx4aypBnysn1OgzxR26ITEoPD0I60ugc&mode=#{default_mode}&departure_time=#{Time.now.to_i}"
          json_obj = do_request(google_api_url, log_result=false)

	  if json_obj["status"].include?("OK")
              txt_contents = get_instructions(json_obj, default_mode)
          elsif json_obj["status"].include?("ZERO_RESULTS")
              if params.include?('FromState') and params.include?('FromCity')
                  logger.info ">>>>>LOG_INFORMATION : Retrying with default city, state : #{params['FromCity']}, #{params['FromState']}"
                  from_address   = "#{feature_params['from_address']}, #{params['FromCity']}, #{params['FromState']}"
                  google_api_url = "https://maps.googleapis.com/maps/api/directions/json?origin=#{from_address}&destination=#{feature_params['to_address']}&sensor=false&key=AIzaSyBYx4aypBnysn1OgzxR26ITEoPD0I60ugc&mode=#{default_mode}&departure_time=#{Time.now.to_i}"
                  json_obj = do_request(google_api_url, log_result=false)
                  if json_obj["status"].include?("OK")
                      txt_contents = get_instructions(json_obj, default_mode)
                      txt_contents << "\nIf your location is not from #{params['FromCity']}, #{params['FromState']}, please include the appropriate <city, state> in the request.\n"
                  else
                      logger.info ">>>>>LOG_INFORMATION : Zero results after retry : #{msg}"
   	              txt_contents << "Routes not found."	
                  end
              else
                  logger.info ">>>>>LOG_INFORMATION : Zero results : #{msg}"
   	          txt_contents << "Routes not found."	
              end
	  else
              logger.info ">>>>>LOG_INFORMATION : ERROR : Unidentified start/end location : #{msg}"
              txt_contents << "Unidentified source/destination location. Please try again with city/state information."
          end
      else
          logger.info ">>>>>LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << "Invalid message format. Message format should be:\nFrom (from-addr) to (to-addr) by car/bus/bike/walk.\nEg. From skydeck chicago to navy pier by car"
      end
      return txt_contents
  end

end
