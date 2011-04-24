require 'spec_helper'

describe Daikon::Client, "connect" do
  subject { Daikon::Client.new(config) }

  before do
    EventMachine::Hiredis.stubs(:connect => nil)
    subject.connect
  end

  context "with overrides" do
    let(:url)    { "redis://8.8.8.8:1234" }
    let(:config) { Daikon::Configuration.new(["-u", url]) }

    it "sets redis to listen on the given port" do
      EventMachine::Hiredis.should have_received(:connect).with(url).once
    end
  end

  context "with defaults" do
    let(:config) { Daikon::Configuration.new([]) }

    it "sets redis to listen on the given port" do
      EventMachine::Hiredis.should have_received(:connect).with("redis://0.0.0.0:6379").once
    end
  end
end

describe Daikon::Client, "when server is down" do
  subject { Daikon::Client.new }

  before do
    subject.stopper = lambda { |client| EventMachine.stop }
    stub_request(:any, infos_url).to_timeout
  end

  it "does not kill the client" do
    em do
      lambda {
        subject.report_info({})
      }.should_not raise_error
    end
  end
end

describe Daikon::Client, "when it returns bad json" do
  subject { Daikon::Client.new }

  before do
    subject.stopper = lambda { |client| EventMachine.stop }
    stub_request(:post, infos_url).to_return(:body => "{'bad':'json}")
  end

  it "does not commit suicide" do
    em do
      lambda {
        subject.report_info({})
      }.should_not raise_error
    end
  end
end

shared_examples_for "a summary api consumer" do
  it "shoots the results back to radish" do
    headers = {
      "Authorization"  => api_key,
      "Content-Length" => payload.to_json.size.to_s,
      "Content-Type"   => "application/json"
    }

    em do
      subject.rotate_monitor(DateTime.parse(past), DateTime.parse(now))
    end

    WebMock.should have_requested(:post, summaries_url(server)).
      with(:body => payload.to_json, :headers => headers)
  end
end

describe Daikon::Client, "rotate monitor" do
  subject    { Daikon::Client.new(config) }
  let(:now)  { "2011-01-19T18:23:55-05:00" }
  let(:past) { "2011-01-19T18:23:54-05:00" }
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
    Timecop.freeze DateTime.parse(now)
    Daikon::Monitor.stubs(:pop).yields(data)
    subject.stopper = lambda { |client| EventMachine.stop }
    stub_request(:post, summaries_url(server)).to_return(:status => 200)
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
      "Content-Length" => info.to_json.size.to_s,
      "Content-Type"   => "application/json"
    }

    em do
      subject.report_info(info)
    end

    WebMock.should have_requested(:post, infos_url(server)).
      with(:body => info.to_json, :headers => headers)
  end
end

describe Daikon::Client, "report info" do
  subject    { Daikon::Client.new(config) }
  let(:info) { {"connected_clients"=>"1", "used_cpu_sys_childrens"=>"0.00"} }

  before do
    subject.stopper = lambda { |client| EventMachine.stop }
    stub_request(:post, infos_url(server)).to_return(:status => 200)
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
