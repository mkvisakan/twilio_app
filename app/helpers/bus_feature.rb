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
      logger.info ">>>>>LOG_INFORMATION : Getting schedule information from SMSAPI...#{msg}"
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
                    txt_contents << "#{elt['routeID']} @ #{elt['arrivalTime']}\n"
                 end
             end
	  else
             for elt in json_obj["stop"]["route"]
		    if elt['routeID'] == "W7"
			next
		    end
		    break if i == 10
		    i= i+1
                    txt_contents << "#{elt['routeID']} @ #{elt['arrivalTime']}\n"
             end
	  end
	  if i<=0
		bus_nos = feature_params['bus_nos']
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
			txt_contents << "Shoot! Bus not available at this hour. Need direction to some place? Text 'More 2' \n"
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
  def get_bus_stopid_by_street_name(msg="")
        logger.info ">>>>>LOG_INFORMATION: Getting nearby places from google API..."
        txt_contents = []
        msg_contents = msg.split('AT',2)[1].strip()
	if (msg_contents =~ /(.*)&(.*)/)
		msg_contents["&"]="and"
	end
        google_api_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{msg_contents} madison wi&sensor=true&key=AIzaSyDvHC2dZhR9I0uMBtLxp0Bq1qulebuTRQY"
        logger.info ">>>>>LOG_INFORMATION : URL: #{URI::encode(google_api_url)}"
        url_open = open(URI::encode(google_api_url))
        json_obj = JSON.load(url_open)
	stop_name = []
        if json_obj.include?("results") && json_obj["results"].any?
          json_results = json_obj["results"]
          counter = 0
	#  for elt in json_results
        #      counter += 1
        #      if counter > 2
        #          break
        #      end
	#      stop_name << elt["name"]
		 
	#  end
	#  lev_dist=0
	#  if counter>1
	#    lev_dist=lev(stop_name[0], stop_name[1])
	#  end
	  counter = 0 
          for elt in json_results
              counter += 1
              if counter >= 2
                  break
              end
	      
             lat= elt["geometry"]["location"]["lat"]
             lng= elt["geometry"]["location"]["lng"]
	     sms_api_url    = "http://api.smsmybus.com/v1/getnearbystops?key=visak&radius=1000&lat=#{lat}&lon=#{lng}"
             json_obj       = do_request(sms_api_url)

       	     i=0;	 
             if json_obj.include? "stop"
                 for elt1 in json_obj["stop"]
                 	i=i+1
		 	if i>2
				break
			end
			stopid = elt1["stopID"]
			stop_name = Bus_stop_names_madison.find_by_id(stopid).stop_name
			intersection = elt1["intersection"]
		        msg_contents1 = "#{msg.split('AT',2)[0].strip()} AT #{stopid}"
			bus_timings = []
			bus_timings =  get_arrival_time_from_sms_api(msg_contents1)
			valid = 0
			valid_timings = []
			count=0;
			for bus in bus_timings
				if count>=5
					break
				end
				if not (bus =~ /(.*)(Invalid|Shoot)(.*)/)
					count +=1
					valid_timings << bus
					valid = 1
				end
			end
			if valid > 0
				txt_contents << "#{stop_name}\n"
				txt_contents << valid_timings
			end
		 end
	     end
	  end	
      else
	  logger.info ">>>>>TEXTME_LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << TextHelper.get_invalid_format(bus)
      end
      m = txt_contents.length 
      if m==0	
	txt_contents << "Can't find bus stations near this place. Try with a more detailed location info or with a stop id. Text - \'More bus\', to know more"
      end
      return txt_contents
  end

def lev(s, t)
  m = s.length
  n = t.length
  return m if n == 0
  return n if m == 0
  d = Array.new(m+1) {Array.new(n+1)}

  (0..m).each {|i| d[i][0] = i}
  (0..n).each {|j| d[0][j] = j}
  (1..n).each do |j|
    (1..m).each do |i|
      d[i][j] = if s[i-1] == t[j-1]  # adjust index into string
                  d[i-1][j-1]       # no operation required
                else
                  [ d[i-1][j]+1,    # deletion
                    d[i][j-1]+1,    # insertion
                    d[i-1][j-1]+1,  # substitution
                  ].min
                end
    end
  end
  d[m][n]
end
end
