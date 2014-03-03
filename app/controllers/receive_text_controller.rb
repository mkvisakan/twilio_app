require 'open-uri'
require 'json'

class ReceiveTextController < ApplicationController
  def index
    begin
        msg = params["Body"]
        from_number = params["From"]

        msg = msg.strip()

        #log input
        logger.info ">>>>>LOG_INFORMATION : #{from_number} : #{msg}"
    
        if msg.start_with?('STOP:')
           txt_contents = get_arrival_time_from_sms_api(msg)
        elsif msg.start_with?('START:')
           txt_contents = get_directions_from_google_api(msg)
        elsif msg.start_with?('NEARBY:')
           txt_contents = get_nearby_from_google_api(msg)
        else
           txt_contents = ["Invalid Message Format !!!", "STOP:1101 BUS:05", "START:2110, University avenue, madison DEST:Computer sciences and statistics, madison, NEARBY: restaurants nearby 2100 university avenue madison"]
        end

        txt_msg = txt_contents.join('.')

        msg_list = txt_msg.chars.each_slice(120).map(&:join)

        twilio_sid = 'AC15a225ec77a2891ead8403d67723d2d0'
        twilio_token = "f1bffe6a8d0a28e9b6068a983cb3a99b"
        twilio_phone_number = "6082162484"

        logger.info ">>>>>LOG_INFORMATION : Sending Msg to #{from_number}..."
        @twilio_client = Twilio::REST::Client.new twilio_sid, twilio_token
   
        counter = 1
        num_msgs = msg_list.length
        for send_msg in msg_list
            send_msg += "::Msg - #{counter}/#{num_msgs}"

            @twilio_client.account.sms.messages.create(
              :from => "+1#{twilio_phone_number}",
              :to => from_number ,
              :body => send_msg
            )
  
            counter += 1
        end
    rescue
         logger.info ">>>>>LOG_INFORMATION : CRASH ERROR : #{$!}"

    ensure
        render text: "Thank you! You will receive an SMS shortly with bus timings."
    end

  end


  def get_nearby_from_google_api(msg="")
      logger.info ">>>>>LOG_INFORMATION : Getting nearby results from google API..."
      txt_contents = []
      msg_contents = msg.split('NEARBY:')[1].strip()
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
              if counter > 5
                  break
              end
              txt_contents << "(#{counter}) #{elt["name"]} at #{elt["formatted_address"]} rated #{elt["rating"]}"
          end
      else
          txt_contents << "Invalid message format. Message Format should be NEARBY: <text>"
      end
      return txt_contents
  end
      


  def get_directions_from_google_api(msg="")
      logger.info ">>>>>LOG_INFORMATION : Getting directions from google API..."
      txt_contents = []
      if msg.include? "DEST:"
          msg_new = msg.split('START:')[1].strip()
          msg_contents = msg_new.split('DEST:').map {|s| s.strip()}
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
              txt_contents << "Unidentified START / DEST location. Please try another location text. Try adding the city / state information."
          end
      else
          logger.info ">>>>>LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << "Invalid message format. Message Format should be START: <text> DEST: <text>"
      end
      return txt_contents
  end


  def get_arrival_time_from_sms_api(msg="")
      logger.info ">>>>>LOG_INFORMATION : Getting schedule information from SMSAPI..."
      txt_contents = []
      if msg.include? "BUS:"
         msg_new = msg.split('STOP:')[1].strip()
         msg_contents = msg_new.split('BUS:').map {|s| s.strip()}
         bus_nos = msg_contents[1].split(',').map {|s| s.strip().to_i}
         sms_api_url = "http://api.smsmybus.com/v1/getarrivals?key=bontrager&stopID=#{msg_contents[0]}"
         logger.info ">>>>>LOG_INFORMATION : URL: #{sms_api_url}"
         url_open = open(sms_api_url)
         json_obj = JSON.load(url_open)
         logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"
 
         if json_obj.include? "stop"
             for elt in json_obj["stop"]["route"]
                 if bus_nos.include? elt['routeID'].to_i
                    txt_contents << "BUS #{elt['routeID']} towards #{elt['destination']} arrives at #{elt['arrivalTime']}\n"
                 end
             end
         else
          logger.info ">>>>>LOG_INFORMATION : ERROR : Unidentfied stop : #{msg}"
          txt_contents << "Unidentified Stop. Please try with the correct stop Id."
         end
      else
          logger.info ">>>>>LOG_INFORMATION : ERROR : Invalid format : #{msg}"
          txt_contents << "Invalid message format. Message Format should be STOP:1101 BUS:05."
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
