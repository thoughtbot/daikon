require 'spec_helper'

describe Daikon::Daemon, "flags" do
  %w[-v --version].each do |flag|
    it "shows the daikon version with #{flag}" do
      old_stdout = $stdout
      $stdout = StringIO.new("")
      Daikon::Daemon.start([flag])
      $stdout.string.should include(Daikon::VERSION)
      $stdout = old_stdout
    end
  end
end
