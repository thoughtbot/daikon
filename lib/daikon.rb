require 'rubygems'
require 'daemons'

class Diakon
  def self.hello
    puts "Hiya!"
  end
end

Daemons.run_proc('daikon') do
  loop do
    Diakon.hello
    sleep(5)
  end
end
