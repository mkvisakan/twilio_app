include TextHelper

module DirectionsFeature

  def extract_params(msg)
      dir_regex      = /FROM *(.*) *TO *(.*) */
      dir_mode_regex = /FROM *(.*) *TO *(.*) *BY *(.*) */
      feature_params = Hash.new
      data_list      = msg.scan(dir_mode_regex)
      if !data_list.any?
          data_list = msg.scan(dir_regex)
      end
      if data_list.any? and data_list[0].length >= 2
          feature_params['from_address'] = data_list[0][1].strip()
          feature_params['to_address']   = data_list[0][1].strip()
          if data_list[0].length >= 3
              feature_params['user_mode'] = data_list[0][2].strip()
          end
      end
      return feature_params
  end

  def found_required_features?(feature_params)
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
	 # if elt["maneuver"] and elt["maneuver"] != 0
	       
	 # end
	      
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

  def get_directions_from_google_api(msg="")
      msg = msg.upcase
      logger.info ">>>>>LOG_INFORMATION : Getting directions from google API..."
      txt_contents = []
      feature_params = extract_params(msg)
      logger.info ">>>>>LOG_INFORMATION : Feature Params : #{feature_params}" 
      if found_required_features?(feature_params)

          default_mode = fetch_transit_mode(feature_params)
          google_api_url = TextHelper.get_url_directions(feature_params['from_address'], feature_params['to_address'], default_mode, Time.now.to_i)
          json_obj = do_request(google_api_url, log_result=false)

	  if json_obj["status"].include?("OK")
              if json_obj.include?("routes") && json_obj["routes"].any?
                  if default_mode.include?("transit")
                      txt_contents = get_transit_instructions(json_obj["routes"][0]["legs"][0]["steps"])
	          else
                      txt_contents = get_driving_instructions(json_obj["routes"][0]["legs"][0]["steps"])
	          end
              else
                  logger.info ">>>>>LOG_INFORMATION : 'Routes not found in json result: #{msg}"
              end
          elsif json_obj["status"].include?("ZERO_RESULTS")
                  logger.info ">>>>>LOG_INFORMATION : Zero results : #{msg}"
	          txt_contents << TextHelper.get_routes_not_found()
	  else
              logger.info ">>>>>LOG_INFORMATION : ERROR : Unidentified start/end location : #{msg}"
              txt_contents << TextHelper.get_unident_loc()
          end
      else
          logger.info ">>>>>LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << TextHelper.get_invalid_format("directions") 
      end
      return txt_contents
  end

end
