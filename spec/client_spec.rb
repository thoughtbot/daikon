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

shared_examples_for "a command api consumer" do
  it "sends a request for commands" do
    WebMock.should have_requested(:get, "#{server}/api/v1/commands.json").
      with(:headers => {'Authorization' => api_key})
  end

  it "processes each command" do
    subject.should have_received(:evaluate_redis).with("INCR foo")
    subject.should have_received(:evaluate_redis).with("DECR foo")
  end

  it "shoots the results back to radish" do
    results = {"response" => "9999"}.to_json

    WebMock.should have_requested(:put, "#{server}/api/v1/commands/42.json").
      with(:body => results, :headers => {'Authorization' => api_key})

    WebMock.should have_requested(:put, "#{server}/api/v1/commands/43.json").
      with(:body => results, :headers => {'Authorization' => api_key})
  end
end

describe Daikon::Client, "fetching commands" do
  subject       { Daikon::Client.new }
  let(:body)    { {"42" => "INCR foo", "43" => "DECR foo"}.to_json }

  before do
    subject.stubs(:evaluate_redis => "9999")
    stub_request(:get, "#{server}/api/v1/commands.json").to_return(:body => body)
    stub_request(:put, %r{#{server}/api/v1/commands/\d+\.json})

    subject.setup(config)
    subject.fetch_commands
  end

  context "with default configuration" do
    let(:api_key) { config.api_key }
    let(:server)  { "https://radishapp.com" }
    let(:config)  { Daikon::Configuration.new([]) }

    it_should_behave_like "a command api consumer"
  end

  context "with custom settings" do
    let(:api_key) { "0987654321" }
    let(:server)  { "http://localhost:9999" }
    let(:config)  { Daikon::Configuration.new(["-k", api_key, "-s", "http://localhost:9999"]) }

    it_should_behave_like "a command api consumer"
  end
end
