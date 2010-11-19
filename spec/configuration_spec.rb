require 'spec_helper'

describe Daikon::Configuration do
  subject     { Daikon::Configuration.new(flags) }
  let(:flags) { %w[-p 9001 -k deadbeef -s localhost:9337 -f 1337] }

  it "parses the given flags" do
    subject.redis_port.should == "9001"
    subject.api_key.should == "deadbeef"
    subject.field_id.should == "1337"
    subject.server_prefix == "localhost:9337"
  end
end

describe Daikon::Configuration do
  subject { Daikon::Configuration.new([]) }

  it "uses the default keys" do
    subject.redis_port.should == "6379"
    subject.api_key.should == "1234567890"
    subject.field_id.should == "1"
    subject.server_prefix == "radishapp.com"
  end
end

describe Daikon::Configuration do
  subject     { Daikon::Configuration.new(flags) }
  let(:flags) { %w[-p 9001 -k deadbeef] }

  it "can handle defaults and given options" do
    subject.redis_port.should == "9001"
    subject.api_key.should == "deadbeef"
    subject.field_id.should == "1"
    subject.server_prefix == "radishapp.com"
  end
end
