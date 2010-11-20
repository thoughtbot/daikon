require 'spec_helper'

describe Daikon::Client, "setup" do
  subject { Daikon::Client.new }
  let(:logger) { Logger.new(nil) }
  let(:redis)  { 'redis instance' }

  before do
    Redis.stubs(:new => redis)
    subject.stubs(:redis=)
  end

  context "with defaults" do
    let(:config) { Daikon::Configuration.new(%w[-p 1234]) }

    before do
      subject.setup(config, logger)
    end

    it "sets redis to listen on the given port" do
      Redis.should have_received(:new).with(:port => "1234")
      subject.should have_received(:redis=).with(redis)
    end
  end

  context "with overrides" do
    let(:config) { Daikon::Configuration.new([]) }

    before do
      subject.setup(config, logger)
    end

    it "sets redis to listen on the given port" do
      Redis.should have_received(:new).with(:port => "6379")
      subject.should have_received(:redis=).with(redis)
    end
  end
end

describe Daikon::Client, "fetching commands" do
  subject       { Daikon::Client.new }
  let(:config)  { Daikon::Configuration.new([]) }
  let(:api_key) { "deadbeef" }
  let(:api_url) { "radishapp.com/api/v1/commands.json" }
  let(:body)    { {"42" => "INCR foo", "43" => "DECR foo"}.to_json }

  before do
    subject.stubs(:evaluate_redis => "9999")
    stub_request(:get, api_url).to_return(:body => body)
    stub_request(:put, %r{radishapp\.com/api/v1/commands/\d+\.json})

    subject.setup(config)
    subject.fetch_commands
  end

  it "sends a request for commands" do
    WebMock.should have_requested(:get, api_url).
      with(:headers => {'Authorization' => api_key})
  end

  it "processes each command" do
    subject.should have_received(:evaluate_redis).with("INCR foo")
    subject.should have_received(:evaluate_redis).with("DECR foo")
  end

  it "shoots the results back to radish" do
    results = {"response" => "9999"}.to_json

    WebMock.should have_requested(:put, "radishapp.com/api/v1/commands/42.json").
      with(:body => results, :headers => {'Authorization' => api_key})

    WebMock.should have_requested(:put, "radishapp.com/api/v1/commands/43.json").
      with(:body => results, :headers => {'Authorization' => api_key})
  end
end
