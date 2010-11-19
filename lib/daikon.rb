require 'rubygems'
require 'thor'

class Daikon < Thor
  desc 'start', 'Start communication with Radish'
  def start
    p "hi!"
  end
end
