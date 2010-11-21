require 'rubygems'
require 'stringio'
require 'logger'
require 'shellwords'
require 'socket'

require 'system_timer'
require 'daemons'
require 'json'
require 'net/http/persistent'
require 'redis'

__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless
  $LOAD_PATH.include?(__DIR__) ||
  $LOAD_PATH.include?(File.expand_path(__DIR__))

require 'daikon/namespace_tools'
require 'daikon/configuration'
require 'daikon/client'
require 'daikon/daemon'

module Daikon
  VERSION = "0.1.1"
end
