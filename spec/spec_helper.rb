$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'daikon'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

require 'timecop'
require 'bourne'

RSpec.configure do |config|
  config.mock_with :mocha

  config.before do
    Daikon::Monitor.reset
  end
end

# http://pivotallabs.com/users/alex/blog/articles/853-capturing-standard-out-in-unit-tests
def capture
  output = StringIO.new
  $stderr = output
  yield
  output.string
ensure
  $stderr = STDERR
end
