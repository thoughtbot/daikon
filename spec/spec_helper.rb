$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'daikon'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'timecop'
require 'bourne'

require 'support/capture_helper'
require 'support/parse_helper'

RSpec.configure do |config|
  config.mock_with :mocha

  config.include CaptureHelper
  config.include ParseHelper

  config.before do
    Daikon::Monitor.reset
  end
end
