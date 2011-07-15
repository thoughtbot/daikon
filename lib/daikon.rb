require 'rubygems'

require 'logger'
require 'shellwords'
require 'set'
require 'socket'
require 'stringio'
require 'thread'
begin
  require 'psych'
rescue LoadError
  # Ignore
end
require 'yaml'

require 'em-hiredis'
require 'em-http-request'
require 'daemons'
require 'json'
require 'redis'

__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require 'daikon/configuration'
require 'daikon/bus'
require 'daikon/client'
require 'daikon/reactor'
require 'daikon/daemon'
require 'daikon/monitor'

require 'daikon/daemons_hacks'

module Daikon
  VERSION = "0.9.2"

  def self.data_dir(path)
    if datadir = Gem.datadir("daikon")
      File.join(datadir, path)
    else
      ""
    end
  end
end
