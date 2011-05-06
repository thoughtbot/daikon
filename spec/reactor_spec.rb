require 'spec_helper'

describe Daikon::Reactor, "start" do
  let(:client) { stub('client', :connect => true) }
  subject { Daikon::Reactor.new(client) }

  before do
    Timecop.return
    subject.stubs(:collect_info)
    subject.info_interval = 1
    subject.summary_interval = 2
    Daikon::Monitor.stubs(:start)
    client.stubs(:rotate_monitor)
  end

  it "collects info once per interval" do
    times = []
    subject.on(:start_info) do
      times << Time.now
      if times.length == 2
        EM.stop
        (times[1] - times[0]).should be_within(0.1).of(subject.info_interval)
      end
    end

    em do
      subject.start
    end
  end

  it "rotates the monitor once per interval" do
    times = []
    subject.on(:start_summary) do
      times << Time.now
      if times.length == 2
        EM.stop
        (times[1] - times[0]).should be_within(0.1).of(subject.summary_interval)
      end
    end

    em do
      subject.start
    end
  end
end

describe Daikon::Reactor, "collecting info" do
  subject      { Daikon::Reactor.new(client) }
  let(:client) { Daikon::Client.new(config) }
  let(:config) { Daikon::Configuration.new(["-u", "redis://127.0.0.1:6380"]) }
  let(:replies) do
    {:info => lambda { "+total_commands_processed:1" }}
  end

  before do
    client.stubs(:report_info)
  end

  it "sends along info to the client" do
    redis_mock(replies) do
      em do
        subject.on(:collected_info) do
          EM.stop
          client.should have_received(:report_info).with(:total_commands_processed => "1")
        end
        subject.collect_info
      end
    end
  end
end

describe Daikon::Reactor, "collecting summary" do
  subject { Daikon::Reactor.new(client) }
  let(:client) { Daikon::Client.new(config) }
  let(:config) { Daikon::Configuration.new(["-u", "redis://127.0.0.1:6380"]) }

  before do
    Daikon::Monitor.stubs(:start)
    subject.summary_interval = 0.5
    client.stubs(:rotate_monitor)
  end

  it "starts the monitor" do
    em do
      subject.on(:started) do
        Daikon::Monitor.should have_received(:start)
        EM.stop
      end
      subject.start
    end
  end

  it "rotates the monitor" do
    em do
      subject.on(:end_summary) do
        client.should have_received(:rotate_monitor)
        EM.stop
      end
      subject.start
    end
  end
end
