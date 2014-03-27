require 'open-uri'
require 'json'


class ReceiveTextController < ApplicationController
  def index
    begin
	welcome_text ="Lets get you started with some examples. Text us:\n1. Bus 2 19 at 2717\n2. From skydeck chicago to navy pier by car\n3. Find 3 bars in boston\nFor more details on our features, message: More 1/2/3. Eg. More 2" 


        help_text = "Usage:\n(1) From skydeck chicago to navy pier by car\n(2) Find 3 restaurants near San Francisco\n(3) Bus 2 19 at 2717\n\n Description:\n(1) To get directions, text: \n\"From (from-addr) to (to-addr) by car/bike/walk/public transit\". Mode of transportation is optional, default is public transit.\n(2) To find nearby places, text:\n\"Find (number) (type-of-place) in/near (location)\". Number of places is optional, default is 5, max is 20.\n(3) To get real time bus info for Madison-WI, text:\n\"Bus (bus-numbers) at (stop-id)\""
        msg = params["Body"]
        from_number = params["From"]
        msg = msg.strip().upcase
	
	if msg.start_with?('FRM ')
	    msg=msg.gsub('FRM','FROM')	
	end
	
        #log input
        logger.info ">>>>>LOG_INFORMATION : #{from_number} : #{msg}"
    
        if msg.start_with?('BUS')
           txt_contents = get_arrival_time_from_sms_api(msg)
        elsif msg.start_with?('FROM ')
           txt_contents = get_directions_from_google_api(msg)
        elsif msg.start_with?('FIND')
           txt_contents = get_nearby_from_google_api(msg)
	elsif msg.start_with?('HELP')
	   txt_contents = ["Hey there! ",welcome_text]
	elsif msg.start_with?('HELLO') or msg.start_with?('HI')
	   txt_contents = ["Welcome aboard! ", welcome_text]
	elsif msg.start_with?('MORE')
	   txt_contents = get_more_help(msg)
        else
           txt_contents = ["Snap! Invalid format. ", welcome_text]
        end

        txt_msg = txt_contents.join('')

        msg_list = txt_msg.chars.each_slice(1550).map(&:join)

        #kumaresh test account
        #twilio_sid = 'AC15a225ec77a2891ead8403d67723d2d0'
        #twilio_token = "f1bffe6a8d0a28e9b6068a983cb3a99b"
        #twilio_phone_number = "6082162484"

	#Salini's test account
        twilio_sid =  'AC80655ad8c5919e905e13320efb8e91b5' #'AC95f0707fde5738dee612f7116f660cab'  
        twilio_token = "0774a2715d2f13f3f89b6102c2b41a47"  #7fa42958117da90bba11838272d75539"   #""
        twilio_phone_number = "7655885542" #"7655899090"
        
	#production account
	#twilio_sid = 'ACcf265d65051471141a150267c117ab82'
 	#twilio_token = "5979bf88a02f53246d2700f0dc6e02ac"
 	#twilio_phone_number = "2625330030"

        counter  = 1
        num_msgs = msg_list.length

        for msg in msg_list
	    if num_msgs > 1
	            msg += "\n::Msg - #{counter}/#{num_msgs}"
            end

            logger.info ">>>>>LOG_INFORMATION : Sending Msg #{counter} to #{from_number}..."
            @twilio_client = Twilio::REST::Client.new twilio_sid, twilio_token
            @twilio_client.account.messages.create(
                  :from => "+1#{twilio_phone_number}",
                  :to => from_number ,
                  :body => msg
                  )
            counter += 1
        end

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


  def get_nearby_from_google_api(msg="")
      logger.info ">>>>>LOG_INFORMATION : Getting nearby results from google API..."
      txt_contents = []
      msg_contents = msg.split('FIND')[1].strip()
      default_no_of_results =5	
      user_given_no_of_results = msg_contents.split()[0][/\d+/]
#	user_given_no_of_results = msg_contents[/\d+/]
      logger.info "#{user_given_no_of_results}"
      if user_given_no_of_results
	default_no_of_results =  user_given_no_of_results.to_i
	msg_contents = msg_contents.split(user_given_no_of_results)
      end
     
      google_api_url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=#{msg_contents}&sensor=true&opennow&key=AIzaSyDvHC2dZhR9I0uMBtLxp0Bq1qulebuTRQY"
      logger.info ">>>>>LOG_INFORMATION : URL: #{URI::encode(google_api_url)}"
      url_open = open(URI::encode(google_api_url))
      json_obj = JSON.load(url_open)
      #logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"

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
      


  def get_directions_from_google_api(msg="")
      logger.info ">>>>>LOG_INFORMATION : Getting directions from google API..."
      txt_contents = []
      if msg.include? " TO "
          msg_new = msg.split('FROM ')[1].strip()
	  from_address = msg_new.split(' TO ')[0].strip()
	  msg_new = msg_new.split(' TO ')[1].strip() 
	  to_address = msg_new.split(' BY ')[0].strip()
	  default_mode ="transit"
	  user_mode = msg_new.split(' BY ')[1]
  	  if user_mode
		if user_mode.include? "CAR"
			default_mode = "driving"
		elsif user_mode.include? "BIKE"
			default_mode = "bicycling"
		elsif user_mode.include? "WALK"
			default_mode = "walking"
		end
	  end
          logger.info ">>>>>LOG_INFORMATION : default mode : #{default_mode}"
	
          google_api_url = "https://maps.googleapis.com/maps/api/directions/json?origin=#{from_address}&destination=#{to_address}&sensor=false&key=AIzaSyBYx4aypBnysn1OgzxR26ITEoPD0I60ugc&mode=#{default_mode}&departure_time=#{Time.now.to_i}"
          logger.info ">>>>>LOG_INFORMATION : URL: #{URI::encode(google_api_url)}"
          url_open = open(URI::encode(google_api_url))
          json_obj = JSON.load(url_open)
          #logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"

	  count=0
	  if json_obj["status"].include?("OK")
          if json_obj.include?("routes") && json_obj["routes"].any?
            if default_mode.include?("transit")
              for elt in json_obj["routes"][0]["legs"][0]["steps"]
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
	    #end
	    #if default_mode.include?("driving")
	    else
		for elt in json_obj["routes"][0]["legs"][0]["steps"]
		  count= count+1
		  d_inst = elt['html_instructions']
		  d_stripped = d_inst.gsub('<b>','')
		  d_stripped= d_stripped.gsub('</b>','')
		  d_stripped = d_stripped.gsub('</div>','.')
		  d_stripped = d_stripped.gsub(/<.*">/,'. ')
		  d_stripped = d_stripped.gsub('&nbsp;','')
		  distance = elt['distance']['text'];
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
	    end
	 end
          elsif json_obj["status"].include?("ZERO_RESULTS")
		txt_contents << "Routes not found."
		
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


  def get_arrival_time_from_sms_api(msg="")
      logger.info ">>>>>LOG_INFORMATION : Getting schedule information from SMSAPI..."
      txt_contents = []
      if msg.include? "AT"
         text = msg.split('BUS')[1].strip()
	 stop_id = text.split('AT')[1].strip()
	 bus_nos = text.split('AT')[0].strip().split(/,| /).map {|s| s.strip().to_i} 

         sms_api_url = "http://api.smsmybus.com/v1/getarrivals?key=bontrager&stopID=#{stop_id}"
         logger.info ">>>>>LOG_INFORMATION : URL: #{sms_api_url}"
         url_open = open(sms_api_url)
         json_obj = JSON.load(url_open)
         logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"

	 txt_contents << "blah\n" 
	 i=0;	 
         if json_obj.include? "stop"
	  if bus_nos.any?
             for elt in json_obj["stop"]["route"]
                 if bus_nos.include? elt['routeID'].to_i
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

  def new_index 
    # let's pretend that we've mapped this action to 
    # http://localhost:3000/sms in the routes.rb file
    
    message_body = params["Body"]
    from_number = params["From"]

    puts from_number
    puts message_body

    render text: "Thank you! You will receive an SMS shortly with bus timings."
  
    msg_parts = message_body.split().map {|s| s.to_i}
    stop_no = msg_parts[0]
    bus_no = msg_parts[1]

    sms_api_url = "http://api.smsmybus.com/v1/getarrivals?key=bontrager&stopID=#{stop_no}"
    puts sms_api_url

    url_open = open(sms_api_url)
    json_obj = JSON.load(url_open)

    to_msg = ""

    for elt in json_obj["stop"]["route"]
        if elt['routeID'].to_i == bus_no
           to_msg += "#{elt['routeID']}  #{elt['arrivalTime']}\n"
        end
    end
 
    twilio_sid = 'AC15a225ec77a2891ead8403d67723d2d0'
    twilio_token = "f1bffe6a8d0a28e9b6068a983cb3a99b"
    twilio_phone_number = "6082162484"

    @twilio_client = Twilio::REST::Client.new twilio_sid, twilio_token

    @twilio_client.account.sms.messages.create(
      :from => "+1#{twilio_phone_number}",
      :to => from_number ,
      :body => to_msg
    )
 
  end
end
