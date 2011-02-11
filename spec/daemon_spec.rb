require 'spec_helper'

describe Daikon::Daemon do
  let(:client) { stub("client") }

  before do
    Daikon::Client.stubs(:new => client)
    Daikon::Daemon.sleep_time = 0.05
    client.stubs(:setup => true,
                 :start_monitor => true,
                 :rotate_monitor => true,
                 :report_info => true)
  end

  it "submits the last minute of data" do
    thread = Thread.new do
      Daikon::Daemon.start(["run", "--", "-k", "1234"], true)
    end
    sleep 3.1
    Daikon::Daemon.run = false
    client.should have_received(:rotate_monitor)
    client.should have_received(:report_info).times(6)
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
