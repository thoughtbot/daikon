require 'spec_helper'

describe Daikon::Configuration do
  subject     { Daikon::Configuration.new(flags) }
  let(:flags) { %w[-h 4.2.2.2 -p 9001 -k deadbeef -s localhost:9337 -f 1337] }

  it "parses the given flags" do
    subject.redis_host.should == "4.2.2.2"
    subject.redis_port.should == "9001"
    subject.api_key.should == "deadbeef"
    subject.field_id.should == "1337"
    subject.server_prefix == "localhost:9337"
  end
end

describe Daikon::Configuration do
  subject { Daikon::Configuration.new(%w[-k 1234567890]) }

  it "uses the default keys" do
    subject.redis_host.should == "127.0.0.1"
    subject.redis_port.should == "6379"
    subject.api_key.should == "1234567890"
    subject.field_id.should == "1"
    subject.server_prefix == "radish.heroku.com"
  end
end

describe Daikon::Configuration do
  %w[start run restart].each do |command|
    it "raises an error if no api key provided when booting daemon with #{command}" do
      capture do
        lambda {
          Daikon::Configuration.new([command])
        }.should raise_error(SystemExit)
      end
    end
  end

  it "raises no errors on other commands" do
    lambda {
      Daikon::Configuration.new(["stop"])
    }.should_not raise_error
  end
end

describe Daikon::Configuration do
  subject     { Daikon::Configuration.new(flags) }
  let(:flags) { %w[-p 9001 -k deadbeef] }

  it "can handle defaults and given options" do
    subject.redis_port.should == "9001"
    subject.api_key.should == "deadbeef"
    subject.field_id.should == "1"
    subject.server_prefix == "radish.heroku.com"
  end
end
