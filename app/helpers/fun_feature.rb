include RequestHelper
include TextHelper

module FunFeature
  def get_fun_message(msg="")
        logger.info ">>>>>LOG_INFORMATION: Getting fun message.."
        txt_contents = []
  	rand_num = Random.rand(Fun_data.count)
        logger.info ">>>>>LOG_INFORMATION: Random num : #{rand_num}"
	story = Fun_data.find_by_id(rand_num).story
	fun_type = Fun_data.find_by_id(rand_num).fun_type
#	if (fun_type=~/Joke(.*)/)
#		txt_contents << "Laugh Out Loud!\n"
#	elsif (fun_type=~/Horror(.*)/)
#		txt_contents << "Dont wanna sleep tonight? Read this! \n"
#	elsif (fun_type=~/CS_Joke(.*)/)
#		txt_contents << "Laugh Out Loud!\n"	
#	end
	txt_contents << story.gsub("\t", "\n")
	return txt_contents
  end
end
