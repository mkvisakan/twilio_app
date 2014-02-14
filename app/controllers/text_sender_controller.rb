class SendTextController < ApplicationController
  def index
  end
 
  def send_text_message
    #twilio_sid = "AC15a225ec77a2891ead8403d67723d2d0"
    twilio_sid = 'PN80ef6cce403c74e3fcc3950c44cbd2e6'
    twilio_token = "f1bffe6a8d0a28e9b6068a983cb3a99b"
    twilio_phone_number = "6082162484"

    @twilio_client = Twilio::REST::Client.new twilio_sid, twilio_token

    @twilio_client.account.sms.messages.create(
      :from => "+1#{twilio_phone_number}",
      :to => '8147776983' ,
      :body => "This is an message. It gets sent to #{from_number}"
    )
 
  end
end
