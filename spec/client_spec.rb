require 'spec_helper'

describe Daikon::Client, "setup" do
  subject { Daikon::Client.new }
  let(:logger) { Logger.new(nil) }
  let(:redis)  { 'redis instance' }

  before do
    Redis.stubs(:connect => redis)
    subject.stubs(:redis=)
  end

  context "with overrides" do
    let(:url)    { "redis://8.8.8.8:1234" }
    let(:config) { Daikon::Configuration.new(["-u", url]) }

    before do
      subject.setup(config, logger)
    end

    it "sets redis to listen on the given port" do
      Redis.should have_received(:connect).with(:url => url).twice
      subject.should have_received(:redis=).with(redis)
    end
  end

  context "with defaults" do
    let(:config) { Daikon::Configuration.new([]) }

    before do
      subject.setup(config, logger)
    end

    it "sets redis to listen on the given port" do
      Redis.should have_received(:connect).with(:url => "redis://0.0.0.0:6379").twice
      subject.should have_received(:redis=).with(redis)
    end
  end
end

describe Daikon::Client, "when server is down" do
  subject       { Daikon::Client.new }
  let(:redis)   { stub("redis instance", :info => {}) }

  before do
    Redis.stubs(:connect => redis)
    http = stub("http", :reset => nil)
    http.stubs(:request).raises(Timeout::Error)
    subject.stubs(:http => http)

    subject.setup(Daikon::Configuration.new)
  end

  it "does not commit suicide" do
    lambda {
      subject.report_info
    }.should_not raise_error
  end
end

describe Daikon::Client, "when it returns bad json" do
  subject       { Daikon::Client.new }
  let(:redis)   { stub("redis instance", :info => {}) }

  before do
    Redis.stubs(:connect => redis)
    http = stub("http", :request => Excon::Response.new(:body => "{'bad':'json}"), :reset => nil)
    subject.stubs(:http => http)

    subject.setup(Daikon::Configuration.new)
  end

  it "does not commit suicide" do
    lambda {
      subject.report_info
    }.should_not raise_error
  end
end

shared_examples_for "a summary api consumer" do
  it "shoots the results back to radish" do
    headers = {
      "Authorization"  => api_key,
      "Content-Length" => payload.to_json.size.to_s,
      "Content-Type"   => "application/json"
    }

    http.should have_received(:reset)
    http.should have_received(:request).with(
      :method  => "POST",
      :path    => "/api/v1/summaries.json",
      :body    => payload.to_json,
      :headers => headers)
  end
end

describe Daikon::Client, "rotate monitor" do
  subject     { Daikon::Client.new }
  let(:http)  { stub("http", :request => Excon::Response.new, :reset => nil) }
  let(:now)   { "2011-01-19T18:23:55-05:00" }
  let(:past)  { "2011-01-19T18:23:54-05:00" }
  let(:payload) do
    data.merge("start" => past, "stop" => now)
  end
  let(:data) do
    {"commands"   => {"GET" => 42},
     "keys"       => {"foo" => 42},
     "namespaces" => {"a" => 42, "global" => 42},
     "totals"     => {"all" => 42, "read" => 42}}
  end

  before do
    Daikon::Monitor.stubs(:pop).yields(data)
    Timecop.freeze DateTime.parse(now)
    subject.stubs(:http => http)
    subject.setup(config)
    subject.rotate_monitor(DateTime.parse(past), DateTime.parse(now))
  end

  after do
    Timecop.return
  end

  context "with default configuration" do
    let(:api_key) { config.api_key }
    let(:server)  { "https://radish.heroku.com" }
    let(:config)  { Daikon::Configuration.new }

    it_should_behave_like "a summary api consumer"
  end

  context "with custom settings" do
    let(:api_key) { "0987654321" }
    let(:server)  { "http://localhost:9999" }
    let(:config)  { Daikon::Configuration.new(["-k", api_key, "-s", "http://localhost:9999"]) }

    it_should_behave_like "a summary api consumer"
  end
end

shared_examples_for "a info api consumer" do
  it "shoots the results back to radish" do
    headers = {
      "Authorization"  => api_key,
      "Content-Length" => results.to_json.size.to_s,
      "Content-Type"   => "application/json"
    }

    http.should have_received(:reset)
    http.should have_received(:request).with(
      :method  => "POST",
      :path    => "/api/v1/infos.json",
      :body    => results.to_json,
      :headers => headers)
  end
end

describe Daikon::Client, "report info" do
  subject       { Daikon::Client.new }
  let(:results) { {"connected_clients"=>"1", "used_cpu_sys_childrens"=>"0.00"} }
  let(:redis)   { stub("redis instance", :info => results) }
  let(:http)    { stub("http", :request => Excon::Response.new, :reset => nil) }

  before do
    subject.stubs(:redis => redis, :http => http)
    subject.setup(config)
    subject.report_info
  end

  context "with default configuration" do
    let(:api_key) { config.api_key }
    let(:server)  { "https://radish.heroku.com" }
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
