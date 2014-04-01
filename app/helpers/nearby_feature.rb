module NearbyFeature

  def extract_nearby_params(msg)
      nearby_regex = /FIND *(\d*) *(.*)/
      feature_params = Hash.new
      data_list      = msg.scan(nearby_regex)
      if data_list.any? and data_list[0][1].strip() != ""
          if data_list[0][0].strip() != ""
              feature_params['num_results'] = data_list[0][0].strip().to_i
          end
          feature_params['query'] = data_list[0][1].strip()
      end
      return feature_params
  end

  def found_required_nearby_params?(feature_params)
      if feature_params.include?('query')
          return true
      end
      return false
  end

  def get_nearby_results(json_obj, default_no_of_results)
      txt_contents = []
      if json_obj.include?("results") && json_obj["results"].any?
          json_results = json_obj["results"]
          counter = 0
          for elt in json_results
              counter += 1
              if counter > default_no_of_results
                  break
              end
	      formatted_address = elt["formatted_address"]
 	      address = formatted_address.split(',')	
              txt_contents << "(#{counter}) #{elt["name"]} at #{address[0].strip()}, #{address[1].strip()}, #{address[2].strip()}\n" # rated #{elt["rating"]}\n"
          end
      elsif json_obj["status"].include? "ZERO_RESULTS"
	  txt_contents << "Results not found."
      end
      return txt_contents
  end

  def get_nearby_from_google_api(msg="")
      logger.info ">>>>>LOG_INFORMATION : Getting nearby results from google API..."
      msg = msg.upcase
      txt_contents = []
      feature_params = extract_nearby_params(msg)
      logger.info ">>>>>LOG_INFORMATION : Feature Params : #{feature_params}" 
      default_no_of_results =5	
      if found_required_nearby_params?(feature_params)

          if feature_params.include?('num_results')
	      default_no_of_results =  feature_params['num_results']
          end
     
          google_api_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{feature_params['query']}&sensor=true&opennow&key=AIzaSyDvHC2dZhR9I0uMBtLxp0Bq1qulebuTRQY"
          json_obj = do_request(google_api_url, log_result=false)
          txt_contents = get_nearby_results(json_obj, default_no_of_results)
      else
          logger.info ">>>>>LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << "Invalid message format. Message format should be:\nFind (num_results) (query)\nEg. Find 3 restaurants near san francisco"
      end

      return txt_contents
  end
end
