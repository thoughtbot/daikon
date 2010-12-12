require 'spec_helper'

describe Daikon::Monitor, "#rotate" do
  it "pops off what is on the queue" do
    subject.parse("INCR foo")
    subject.parse("DECR foo")

    data = subject.rotate
    data.first[:command].should == "INCR foo"
    data.last[:command].should  == "DECR foo"
    data.size.should == 2
    subject.queue.size.should be_zero
  end
end

describe Daikon::Monitor, "#parse with new format" do
  subject    { Daikon::Monitor.new }
  let(:line) { '1291699658.994073 "decrby" "fooz" "2000"' }

  it "parses the log into json" do
    subject.parse(line)
    subject.queue.should include({:at => 1291699658.994073, :command => '"decrby" "fooz" "2000"'})
  end
end

describe Daikon::Monitor, "#parse with multiple inputs" do
  subject { Daikon::Monitor.new }
  before  { Timecop.freeze }
  after   { Timecop.return }

  it "queues up multiple lines" do
    subject.parse("+OK")
    subject.parse("INCR foo")
    subject.parse("INCR fooz")
    subject.parse("info")

    subject.queue.size.should == 3
    subject.queue.should include({:at => Time.now.to_f, :command => 'INCR foo'})
    subject.queue.should include({:at => Time.now.to_f, :command => 'INCR fooz'})
    subject.queue.should include({:at => Time.now.to_f, :command => 'info'})
  end
end

describe Daikon::Monitor, "#parse with old multi line input" do
  subject { Daikon::Monitor.new }
  before  { Timecop.freeze }
  after   { Timecop.return }

  it "parses gzipped logs into raws" do
    subject.parse("incr foo")
    subject.parse("sismember project-13897-global-error-classes 17")
    subject.parse("incrApiParameterError")
    subject.parse("decr foo")

    subject.queue.size.should == 3
    subject.queue.should include({:at => Time.now.to_f, :command => 'incr foo'})
    subject.queue.should include({:at => Time.now.to_f, :command => 'sismember project-13897-global-error-classes 17'})
    subject.queue.should include({:at => Time.now.to_f, :command => 'decr foo'})
  end
end

describe Daikon::Monitor, "#parse with multi line input with numbers" do
  subject { Daikon::Monitor.new }
  before  { Timecop.freeze }
  after   { Timecop.return }

  it "parses gzipped logs into raws" do
    subject.parse("incr foo")
    subject.parse("set g:2470920:mrn 9")
    subject.parse("554079885")
    subject.parse("decr foo")

    subject.queue.size.should == 3
    subject.queue.should include({:at => Time.now.to_f, :command => 'incr foo'})
    subject.queue.should include({:at => Time.now.to_f, :command => 'set g:2470920:mrn 9'})
    subject.queue.should include({:at => Time.now.to_f, :command => 'decr foo'})
  end
end

describe Daikon::Monitor, "#parse with strings that may to_i to a number" do
  subject { Daikon::Monitor.new }
  before  { Timecop.freeze }
  after   { Timecop.return }

  it "parses gzipped logs into raws" do
    subject.parse("incr foo")
    subject.parse("set g:2470920:mrn 9")
    subject.parse("46fdcf77c1bb2108e6191602c2f5f9ae")
    subject.parse("decr foo")

    subject.queue.size.should == 3
    subject.queue.should include({:at => Time.now.to_f, :command => 'incr foo'})
    subject.queue.should include({:at => Time.now.to_f, :command => 'set g:2470920:mrn 9'})
    subject.queue.should include({:at => Time.now.to_f, :command => 'decr foo'})
  end
end
