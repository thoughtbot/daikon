require 'spec_helper'

describe Daikon::Reactor, "start" do
  subject { Daikon::Reactor.new }

  before do
    Timecop.return
    subject.stubs(:collect_info)
    subject.info_interval = 0.2
  end

  it "collects info once per interval" do
    now = Time.now
    subject.callback = lambda { |reactor| reactor.current_time.to_f >= now.to_f + 1.1 }

    em do
      subject.start
    end

    subject.should have_received(:collect_info).times(5)
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
        subject.collect_info
        subject.callback = lambda do |reactor|
          client.should have_received(:report_info).with(:total_commands_processed => "1")
        end
      end
    end
  end
end
