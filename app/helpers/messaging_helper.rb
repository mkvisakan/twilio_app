module MessagingHelper

      #kumaresh test account
      TWILIO_SID       = 'AC15a225ec77a2891ead8403d67723d2d0'
      TWILIO_TOKEN     = "f1bffe6a8d0a28e9b6068a983cb3a99b"
      TWILIO_PHONE_NO  = "6082162484"

      #Salini's test account
      #TWILIO_SID       =  'AC80655ad8c5919e905e13320efb8e91b5' #'AC95f0707fde5738dee612f7116f660cab'  
      #TWILIO_TOKEN     = "0774a2715d2f13f3f89b6102c2b41a47"  #7fa42958117da90bba11838272d75539"   #""
      #TWILIO_PHONE_NO  = "7655885542" #"7655899090"
        
      #production account
      #TWILIO_SID          = 'ACcf265d65051471141a150267c117ab82'
      #TWILIO_TOKEN        = "5979bf88a02f53246d2700f0dc6e02ac"
      #TWILIO_PHONE_NO     = "2625330030"


  def send_message(txt_contents, from_no)
      txt_msg = txt_contents.join('')

      msg_list = txt_msg.chars.each_slice(1550).map(&:join)

      counter  = 1
      num_msgs = msg_list.length

      for msg in msg_list
          if num_msgs > 1
	      msg += "\n::Msg - #{counter}/#{num_msgs}"
          end

          logger.info ">>>>>LOG_INFORMATION : Sending Msg #{counter} to #{from_no}..."
          @twilio_client = Twilio::REST::Client.new TWILIO_SID, TWILIO_TOKEN
          @twilio_client.account.messages.create(
                  :from => "+1#{TWILIO_PHONE_NO}",
                  :to   => from_no ,
                  :body => msg
                  )
          counter += 1
      end
  end

end
