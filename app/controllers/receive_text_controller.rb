require 'open-uri'
require 'json'


class ReceiveTextController < ApplicationController
  def index
    begin
        msg = params["Body"]
        from_number = params["From"]

        msg = msg.strip().upcase

        #log input
        logger.info ">>>>>LOG_INFORMATION : #{from_number} : #{msg}"
    
        if msg.start_with?('BUS')
           txt_contents = get_arrival_time_from_sms_api(msg)
        elsif msg.start_with?('FROM')
           txt_contents = get_directions_from_google_api(msg)
        elsif msg.start_with?('FIND')
           txt_contents = get_nearby_from_google_api(msg)
	elsif msg.start_with?('HELP')
	   txt_contents = get_help(msg)
        else
           txt_contents = ["Invalid Message Format.", " Here are some examples to assist you:\n", "(1) To get real time bus information - text \"Bus 37 at 178\"\n", "(2) To get directions - text \"From 2110 University Avenue Madison to Union South Madison\"\n", " (3) To find nearby places - text \"Find bars near Dayton Street Madison WI\"\n" ,"(4) To get help - text \"Help me\""]
        end

        txt_msg = txt_contents.join('')

       # msg_list = txt_msg.chars.each_slice(120).map(&:join)

        #twilio_sid = 'AC15a225ec77a2891ead8403d67723d2d0'
        #twilio_token = "f1bffe6a8d0a28e9b6068a983cb3a99b"
        #twilio_phone_number = "6082162484"

        #twilio_sid = 'AC80655ad8c5919e905e13320efb8e91b5'
        #twilio_token = "0774a2715d2f13f3f89b6102c2b41a47"
        #twilio_phone_number = "7655885542"
        
	twilio_sid = 'ACcf265d65051471141a150267c117ab82'
        twilio_token = "5979bf88a02f53246d2700f0dc6e02ac"
        twilio_phone_number = "2625330030"
        
        logger.info ">>>>>LOG_INFORMATION : Sending Msg to #{from_number}..."
        @twilio_client = Twilio::REST::Client.new twilio_sid, twilio_token
     @twilio_client.account.messages.create(
              :from => "+1#{twilio_phone_number}",
              :to => from_number ,
              :body => txt_msg
            )

    rescue
         logger.info ">>>>>LOG_INFORMATION : CRASH ERROR : #{$!}"

    ensure
        render text: "Thank you! You will receive an SMS shortly with bus timings."
    end

  end
  def get_help(msg="")
	txt_contents=["(1) Get real time bus info by texting \"Bus <bus-no(s)> at <stop-id>\" Eg. Bus 2 19 at 2717\n(2) Get directions by texting \"From <from_addr> to <to_addr>\". Eg. From Madison, Wisconsin to Chicago, IL.\n(3) Find the places nearby by texting \"Find <number_of_results> <type_of_place>\". The parameter <number_of_results> is optional, default is 5. Eg. Find 3 restaurants near San Francisco "]
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
      if msg.include? "TO:"
          msg_new = msg.split('FROM:')[1].strip()
          msg_contents = msg_new.split('TO:').map {|s| s.strip()}
          google_api_url = "https://maps.googleapis.com/maps/api/directions/json?origin=#{msg_contents[0]}&destination=#{msg_contents[1]}&sensor=false&key=AIzaSyBYx4aypBnysn1OgzxR26ITEoPD0I60ugc&avoid=highways&mode=transit&departure_time=#{Time.now.to_i}"
          logger.info ">>>>>LOG_INFORMATION : URL: #{URI::encode(google_api_url)}"
          url_open = open(URI::encode(google_api_url))
          json_obj = JSON.load(url_open)
          logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"


          if json_obj.include?("routes") && json_obj["routes"].any?
              for elt in json_obj["routes"][0]["legs"][0]["steps"]
                 if elt["travel_mode"] == "TRANSIT"
                     txt_contents << "#{elt['transit_details']['line']['short_name']} #{elt['html_instructions']} at #{elt['transit_details']['arrival_time']['text']}"
                     txt_contents << "Get down at #{elt['transit_details']['arrival_stop']['name']}"
                 elsif elt["travel_mode"] == "WALKING"
                     txt_contents << elt["html_instructions"]
                 end
              end
          else
              logger.info ">>>>>LOG_INFORMATION : ERROR : Unidentified start/end location : #{msg}"
              txt_contents << "Unidentified FROMTOO location. Please try another location text. Try adding the city / state information."
          end
      else
          logger.info ">>>>>LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << "Invalid message format. Message Format should be FROM: <address> TO: <address>"
      end
      return txt_contents
  end


  def get_arrival_time_from_sms_api(msg="")
      logger.info ">>>>>LOG_INFORMATION : Getting schedule information from SMSAPI..."
      txt_contents = []
      if msg.include? "AT"
         text = msg.split('BUS')[1].strip()
	 stop_id = text.split('AT')[1].strip()
	 bus_nos = text.split('at')[0].strip().split(/,| /).map {|s| s.strip().to_i} 

         sms_api_url = "http://api.smsmybus.com/v1/getarrivals?key=bontrager&stopID=#{stop_id}"
         logger.info ">>>>>LOG_INFORMATION : URL: #{sms_api_url}"
         url_open = open(sms_api_url)
         json_obj = JSON.load(url_open)
         logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"
 
	 i=0;	 
         if json_obj.include? "stop"
             for elt in json_obj["stop"]["route"]
                 if bus_nos.include? elt['routeID'].to_i
		    i= i+1
                    txt_contents << "BUS #{elt['routeID']} towards #{elt['destination']} arrives at #{elt['arrivalTime']}\n"
                 end
             end
	     if i<=0
		 txt_contents << "Invalid bus number or bus not available at this hour"
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
          txt_contents << "Invalid message format. Message format should be BUS <bus-no(s)> at <stop_id>. Eg. BUS 2 19 at 178"
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
