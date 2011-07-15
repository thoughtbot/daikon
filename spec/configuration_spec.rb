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

  it "does not fail if --help option given" do
    capture do
      lambda {
        Daikon::Configuration.new(%w[--help])
      }.should_not raise_error(SystemExit)
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

describe Daikon::Configuration, "with daikon.yml with 1 redis" do
  let(:api_key){ "magic_key" }
  let(:redis_url){ "redis://0.0.0.0:6380" }
  let(:server_prefix){ "orange" }
  let(:yaml) do
    <<-YML
---
daikon:
  api_key: #{api_key}
  redis_url: #{redis_url}
  server_prefix: #{server_prefix}
  YML
  end

  before do
    open('daikon.yml', 'w+'){ |f| f.write(yaml) }
  end

  after do
    File.delete('daikon.yml')
  end

  it "reads options from daikon.yml" do
    configuration = Daikon::Configuration.new
    configuration.api_key.should       == api_key
    configuration.redis_url.should     == redis_url
    configuration.server_prefix.should == server_prefix
  end

  it "prefers api_key from ARGV" do
    api_key_from_argv = 'a_different_key'
    configuration = Daikon::Configuration.new(['-k', api_key_from_argv])
    configuration.api_key.should == api_key_from_argv
  end

  it "prefers redis_url from ARGV" do
    redis_url_from_argv = 'redis://0.0.0.0:5000'
    configuration = Daikon::Configuration.new(['-u', redis_url_from_argv])
    configuration.redis_url.should == redis_url_from_argv
  end

  it "prefers server_prefix from ARGV" do
    server_prefix_from_argv = 'my_prefix'
    configuration = Daikon::Configuration.new(['-s', server_prefix_from_argv])
    configuration.server_prefix.should == server_prefix_from_argv
  end
end
