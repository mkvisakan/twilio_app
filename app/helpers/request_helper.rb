module RequestHelper

  def do_request(url)
      logger.info ">>>>>LOG_INFORMATION : URL: #{url}"
      url_open = open(url)
      json_obj = JSON.load(url_open)
      logger.info ">>>>>LOG_INFORMATION : JSON_RESULT: #{json_obj}"
      return json_obj
  end


end
