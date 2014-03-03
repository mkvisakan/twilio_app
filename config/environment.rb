# Load the Rails application.
require File.expand_path('../application', __FILE__)
require 'log4r'

# Initialize the Rails application.
TwilioApp::Application.initialize!

#Logger files
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger = Log4r::Logger.new("Application Log")

#outputter = Log4r::FileOutputter.new('log4r', :filename => "textme.log")
#outputter.formatter = Log4r::PatternFormatter.new(:date_pattern => "%FT%T.000Z", :pattern => "%d [%l] %m")

#ActiveRecord::Base.logger = Log4r::Logger.new('log4r')
#ActiveRecord::Base.logger.outputters = [outputter]

