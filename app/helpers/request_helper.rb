require 'open-uri'

module RequestHelper

  def do_request(url, log_result=true)
      url = URI::encode(url) 
      logger.info ">>>>>LOG_INFORMATION : URL: #{url}"
      url_open = open(url)
      json_obj = JSON.load(url_open)
      if log_result
          logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"
      end
      return json_obj
  end


end
