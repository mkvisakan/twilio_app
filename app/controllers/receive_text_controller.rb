class ReceiveTextController < ApplicationController
  def index 
    # let's pretend that we've mapped this action to 
    # http://localhost:3000/sms in the routes.rb file
    
    message_body = params["Body"]
    from_number = params["From"]
 
    twilio_sid = 'AC15a225ec77a2891ead8403d67723d2d0'
    twilio_token = "f1bffe6a8d0a28e9b6068a983cb3a99b"
    twilio_phone_number = "6082162484"

    @twilio_client = Twilio::REST::Client.new twilio_sid, twilio_token

    @twilio_client.account.sms.messages.create(
      :from => "+1#{twilio_phone_number}",
      :to => from_number ,
      :body => "This is an message. It gets sent to #{from_number}"
    )
 
  end
end
