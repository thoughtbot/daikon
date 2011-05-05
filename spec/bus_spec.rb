require 'spec_helper'

describe Daikon::Bus, 'emit' do
  subject { Object.new.extend(Daikon::Bus) }
  let(:channel) { stub('channel') }
  before do
    channel.stubs(:push)
    EM::Channel.stubs(:new => channel)
  end

  it "publishes to the channel" do
    subject.emit(:doom)
    channel.should have_received(:push).with(:doom)
  end

end

describe Daikon::Bus, 'on' do
  subject { Object.new.extend(Daikon::Bus) }
  let(:in_block) { stub('in block') }
  before { in_block.stubs(:foo) }

  it "calls the block for the event" do
    em do
      subject.on(:doom) do
        in_block.foo
        EM.stop
      end
      subject.emit(:doom)
    end
    in_block.should have_received(:foo)
  end
end
