require 'spec_helper'

describe Daikon::Client, "setup" do
  subject { Daikon::Client.new }
  let(:logger) { Logger.new(nil) }
  let(:redis)  { 'redis instance' }

  before do
    Redis.stubs(:new => redis)
    subject.stubs(:redis=)
  end

  context "with overrides" do
    let(:config) { Daikon::Configuration.new(%w[-h 8.8.8.8 -p 1234]) }

    before do
      subject.setup(config, logger)
    end

    it "sets redis to listen on the given port" do
      Redis.should have_received(:new).with(:host => "8.8.8.8", :port => "1234").twice
      subject.should have_received(:redis=).with(redis)
    end
  end

  context "with defaults" do
    let(:config) { Daikon::Configuration.new([]) }

    before do
      subject.setup(config, logger)
    end

    it "sets redis to listen on the given port" do
      Redis.should have_received(:new).with(:host => "127.0.0.1", :port => "6379").twice
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

    headers = {
      "Authorization"  => api_key,
      "Content-Length" => results.size.to_s,
      "Content-Type"   => "application/json"
    }

    WebMock.should have_requested(:put, "#{server}/api/v1/commands/42.json").
      with(:body => results, :headers => headers)

    WebMock.should have_requested(:put, "#{server}/api/v1/commands/43.json").
      with(:body => results, :headers => headers)
  end
end

describe Daikon::Client, "fetching commands" do
  subject       { Daikon::Client.new }
  let(:body)    { {"42" => "INCR foo", "43" => "DECR foo"}.to_json }

  before do
    subject.stubs(:evaluate_redis => 9999)
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

describe Daikon::Client, "when server is down" do
  subject       { Daikon::Client.new }
  before do
    subject.setup(Daikon::Configuration.new)
    WebMock.stub_request(:any, /#{subject.config.server_prefix}.*/).to_raise(Timeout::Error)
  end

  it "does not commit suicide" do
    lambda {
      subject.fetch_commands
    }.should_not raise_error
  end
end

describe Daikon::Client, "when it returns bad json" do
  subject       { Daikon::Client.new }
  before do
    subject.setup(Daikon::Configuration.new)
    WebMock.stub_request(:any, /#{subject.config.server_prefix}.*/).to_return(:body => "{'bad':'json}")
  end

  it "does not commit suicide" do
    lambda {
      subject.fetch_commands
    }.should_not raise_error
  end
end

shared_examples_for "a info api consumer" do
  it "shoots the results back to radish" do

    headers = {
      "Authorization"  => api_key,
      "Content-Length" => results.to_json.size.to_s,
      "Content-Type"   => "application/json"
    }

    WebMock.should have_requested(:post, "#{server}/api/v1/info.json").
      with(:body => results.to_json, :headers => headers)
  end
end

describe Daikon::Client, "report info" do
  subject       { Daikon::Client.new }
  let(:results) { {"connected_clients"=>"1", "used_cpu_sys_childrens"=>"0.00"}.to_json }
  let(:redis)   { stub("redis instance", :info => results) }

  before do
    stub_request(:post, "#{server}/api/v1/info.json")
    subject.stubs(:redis => redis)
    subject.setup(config)
    subject.report_info
  end

  context "with default configuration" do
    let(:api_key) { config.api_key }
    let(:server)  { "https://radishapp.com" }
    let(:config)  { Daikon::Configuration.new }

    it_should_behave_like "a info api consumer"
  end

  context "with custom settings" do
    let(:api_key) { "0987654321" }
    let(:server)  { "http://localhost:9999" }
    let(:config)  { Daikon::Configuration.new(["-k", api_key, "-s", "http://localhost:9999"]) }

    it_should_behave_like "a info api consumer"
  end
end

shared_examples_for "a monitor api consumer" do
  it "shoots the results back to radish" do
    payload = {"lines" => lines}

    headers = {
      "Authorization"  => api_key,
      "Content-Length" => payload.to_json.size,
      "Content-Type"   => "application/x-gzip"
    }

    WebMock.should have_requested(:post, "#{server}/api/v1/monitor").
      with(:body => payload.to_json, :headers => headers)
  end
end

describe Daikon::Client, "rotate monitor" do
  subject       { Daikon::Client.new }
  let(:results) { %{1290289048.96581 "info"\n1290289053.568815 "info"} }
  let(:redis)   { stub("redis instance", :info => results) }
  let(:lines) do
    [{"at" => Time.at(1290289048, 96581),  "command" => "info"},
     {"at" => Time.at(1290289053, 568815), "command" => "info"}]
  end

  before do
    stub_request(:post, "#{server}/api/v1/monitor")
    subject.setup(config)
    subject.monitor = stub("monitor", :rotate => lines)
    subject.rotate_monitor
  end

  context "with default configuration" do
    let(:api_key) { config.api_key }
    let(:server)  { "https://radishapp.com" }
    let(:config)  { Daikon::Configuration.new }

    it_should_behave_like "a monitor api consumer"
  end

  context "with custom settings" do
    let(:api_key) { "0987654321" }
    let(:server)  { "http://localhost:9999" }
    let(:config)  { Daikon::Configuration.new(["-k", api_key, "-s", "http://localhost:9999"]) }

    it_should_behave_like "a monitor api consumer"
  end
end

describe Daikon::Client, "pretty printing results" do
  subject      { Daikon::Client.new }
  let(:body)   { {"13" => "LRANGE foo 0 -1"}.to_json }
  let(:list)   { %w[apples bananas carrots] }
  let(:server) { "https://radishapp.com" }
  let(:config) { Daikon::Configuration.new }

  before do
    subject.stubs(:evaluate_redis => list)
    stub_request(:get, "#{server}/api/v1/commands.json").to_return(:body => body)
    stub_request(:put, %r{#{server}/api/v1/commands/\d+\.json})
    subject.setup(config)
    subject.fetch_commands
  end

  it "returns pretty printed results" do
    WebMock.should have_requested(:put, "#{server}/api/v1/commands/13.json").
      with(:body => {"response" => "[\"apples\", \"bananas\", \"carrots\"]"})
  end
end
