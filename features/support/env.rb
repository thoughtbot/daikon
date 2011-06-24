require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'daikon'

require 'aruba/cucumber'
require 'rspec/expectations'

Before do
  kill_daikon

  @dirs = ["."]
  @aruba_timeout_seconds = 5
end

After do
  kill_daikon

  if @env_vars
    @env_vars.each do |key|
      set_env(key, nil)
    end
  end
end

module KillHelpers
  def kill_daikon
    if File.exist?("daikon.pid")
      system "bundle exec ruby -Ilib ./bin/daikon stop"
      system "kill -INT $(pgrep -f daikon)"
      FileUtils.rm_rf("*.pid")
    end
  end
end

World(KillHelpers)
