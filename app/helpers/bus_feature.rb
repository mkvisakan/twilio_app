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
      logger.info ">>>>>LOG_INFORMATION : Getting schedule information from SMSAPI...#{msg}"
      txt_contents = []
      feature_params = extract_params(msg)
	feature_params = Hash.new
      if msg.include? "BUS"
         text = msg.split('BUS')[1].strip()
         feature_params['stop_id'] = text.split('AT')[1].strip()
         feature_params['bus_nos'] = text.split('AT')[0].strip().split(/,| /).map {|s| s.strip().to_i}
      end
      logger.info ">>>>>LOG_INFORMATION : Feature Params : #{feature_params}" 
      if feature_params.include?('stop_id')
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
  def get_bus_stopid_by_street_name(msg="")
        logger.info ">>>>>LOG_INFORMATION: Getting nearby places from google API..."
        txt_contents = []
        msg_contents = msg.split('AT')[1].strip()
	## Fixes for getting better results
	if (msg_contents =~ /(.*)&(.*)/)
		msg_contents["&"]=""
	end
	logger.info ">>>>>LOG_INFORMATION: #{msg_contents}"
        google_api_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{msg_contents} madison wi&sensor=true&key=AIzaSyDvHC2dZhR9I0uMBtLxp0Bq1qulebuTRQY"
        logger.info ">>>>>LOG_INFORMATION : URL: #{URI::encode(google_api_url)}"
        url_open = open(URI::encode(google_api_url))
        json_obj = JSON.load(url_open)
	stop_name = []
        #logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"
        if json_obj.include?("results") && json_obj["results"].any?
          json_results = json_obj["results"]
          counter = 0
	  for elt in json_results
              counter += 1
              if counter > 2
                  break
              end
	      stop_name << elt["name"]
		 
	  end
	  lev_dist=0
	  if counter>1
	    lev_dist=lev(stop_name[0], stop_name[1])
	  end
	  logger.info ">>>>>LOG_INFORMATION : Lev distance #{lev_dist}"
	  if lev_dist >0 and lev_dist <5
		txt_contents << "If you meant"
		txt_contents << "\"#{stop_name[0]}\", Text \"#{msg.split('AT')[0].strip()} AT #{stop_name[0]}\""
		txt_contents << "If you meant"
		txt_contents << "\"#{stop_name[1]}\", Text \"#{msg.split('AT')[0].strip()} AT #{stop_name[1]}\""
		 txt_contents << "Otherwise, Please specify a detailed address"
	  else
	  counter = 0 
          for elt in json_results
              counter += 1
              if counter >= 2
                  break
              end
	      
             lat= elt["geometry"]["location"]["lat"]
             lng= elt["geometry"]["location"]["lng"]
	     sms_api_url    = "http://api.smsmybus.com/v1/getnearbystops?key=visak&lat=#{lat}&lon=#{lng}"
             json_obj       = do_request(sms_api_url)

       	     i=0;	 
             if json_obj.include? "stop"
                 for elt1 in json_obj["stop"]
                 	i=i+1
		 	if i>=2
				break
			end
			stopid = elt1["stopID"]
		        msg_contents1 = "#{msg.split('AT')[0].strip()} AT #{stopid}"
			txt_contents = get_arrival_time_from_sms_api(msg_contents1) 
			txt_contents << "STOP: #{stopid}"
		 end
	     end
	  end	
	  end	
      else
          txt_contents << "Invalid message format. Message Format should be FINFINDxt>"
      end
      return txt_contents
  end

def lev(s, t)
  logger.info ">>>>>LOG_INFORMATION : Lev distance #{s} #{t}"
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
