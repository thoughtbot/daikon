require 'spec_helper'

describe Daikon::Configuration do
  subject     { Daikon::Configuration.new(flags) }
  let(:flags) { %w[-u redis://4.2.2.2:9001 -k deadbeef -s localhost:9337] }

  it "parses the given flags" do
    subject.redis_url.should == "redis://4.2.2.2:9001"
    subject.api_key.should == "deadbeef"
    subject.server_prefix == "localhost:9337"
  end
end

describe Daikon::Configuration do
  subject { Daikon::Configuration.new(%w[-k 1234567890]) }

  it "uses the default keys" do
    subject.redis_url.should == "redis://0.0.0.0:6379"
    subject.api_key.should == "1234567890"
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
  it "fails if -h option given" do
    capture do
      lambda {
        Daikon::Configuration.new(%w[-h 8.8.8.8])
      }.should raise_error(SystemExit)
    end
  end

  it "fails if -p option given" do
    capture do
      lambda {
        Daikon::Configuration.new(%w[-p 6380])
      }.should raise_error(SystemExit)
    end
  end
end
