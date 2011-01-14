require 'spec_helper'

describe Daikon::Daemon do
  let(:client) { stub("client") }

  before do
    Daikon::Client.stubs(:new => client)
    Daikon::Daemon.sleep_time = 0.01
    client.stubs(:setup => true, :start_monitor => true, :rotate_monitor => true)
  end

  it "submits the last minute of data" do
    thread = Thread.new do
      Daikon::Daemon.start(["run", "--", "-k", "1234"], true)
    end
    sleep 0.65
    Daikon::Daemon.run = false
    client.should have_received(:rotate_monitor)
  end
end

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
