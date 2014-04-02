require 'open-uri'
require 'json'

module FeaturesHelper

  BUS_FEATURE        = 1
  NEARBY_FEATURE     = 2
  DIRECTIONS_FEATURE = 3
  HELP_FEATURE       = 4 
  HELLO_FEATURE      = 5
  MORE_FEATURE       = 6
  INVALID_FEATURE    = 7
  FUN_FEATURE	     = 8
  def identify_request_type(msg)
      msg = msg.strip().upcase
      if is_bus_feature?(msg)
          return BUS_FEATURE
      elsif is_nearby_feature?(msg)
          return NEARBY_FEATURE
      elsif is_directions_feature?(msg)
          return DIRECTIONS_FEATURE
      elsif is_help_feature?(msg)
          return HELP_FEATURE
      elsif is_hello_feature?(msg)
          return HELLO_FEATURE
      elsif is_fun_feature?(msg)
	  return FUN_FEATURE
      elsif is_more_feature?(msg)
          return MORE_FEATURE
      else
          return INVALID_FEATURE
      end
  end

  def start_with?(msg, kwds)
      msg = msg +" "
      for kwd in kwds
          if msg.start_with?("#{kwd.upcase} ") 
              return true
          end 
      end 
      return false
  end  

  def is_bus_feature?(msg)
      kwds = ['BUS', 'TRANSIT']
      if start_with?(msg, kwds)
          return true
      end
      return false
  end

  def is_nearby_feature?(msg)
      kwds = ['FIND', 'GET ME']
      if start_with?(msg, kwds)
          return true
      end
      return false
  end

  def is_directions_feature?(msg)
      kwds = ['FROM', 'FRM']
      if start_with?(msg, kwds)
          return true
      end
      return false
  end

  def is_help_feature?(msg)
      kwds = ['HELP', 'HELPME', 'HLP']
      if start_with?(msg, kwds)
      #if (msg.strip=~ /(HELP|HLP)(.*)/)
          return true
      end
      return false
  end

  def is_hello_feature?(msg)
      kwds = ['HELLO', 'HI']
      if start_with?(msg, kwds)
      #if (msg.strip=~ /(HELLO|HI)(.*)/)
          return true
      else
	 puts "<<< LOG: #{msg}" 
      end
      return false
  end

  def is_more_feature?(msg)
      kwds = ['MORE']
      if start_with?(msg, kwds)
          return true
      end
      return false
  end

  def is_fun_feature?(msg)
      if (msg.strip=~ /(FUN|ENTERTAIN|JOKE)(.*)/)
          return true
      end
      return false
  end
end
