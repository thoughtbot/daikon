require 'rubygems'

require 'logger'
require 'shellwords'
require 'set'
require 'socket'
require 'stringio'
require 'thread'

require 'excon'
require 'daemons'
require 'json'
require 'redis'

__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require 'daikon/namespace_tools'
require 'daikon/configuration'
require 'daikon/client'
require 'daikon/daemon'
require 'daikon/monitor'
require 'daikon/redis_hacks'

module Daikon
  VERSION = "0.6.0"
end
