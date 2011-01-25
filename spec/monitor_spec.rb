require 'spec_helper'

describe Daikon::Monitor, "#rotate" do
  before do
    subject.parse("INCR foo")
    subject.parse("DECR foo")
    subject.parse("DECR baz")
    subject.parse("HGETALL faz")
    subject.parse("PING")
  end

  it "clears out current data" do
    subject.rotate
    subject.data["commands"].size.should be_zero
    subject.data["totals"].size.should be_zero
    subject.data["keys"].size.should be_zero
  end

  it "only saves the top 100 key listings" do
    150.times { |n| subject.parse("INCR foo#{n}") }
    150.times { |n| subject.parse("DECR foo#{n}") }
    100.times { |n| subject.parse("DEL foo#{n}") }
    data = subject.rotate
    data["keys"].size.should == 100
    data["keys"].values.all? { |n| n == 3 }.should be_true
  end

  it "santizes key names" do
    subject.parse("INCR $foo.zomg")
    data = subject.rotate
    data["keys"]["$foo.zomg"].should be_nil
    data["keys"]["{DOLLAR}foo{PERIOD}zomg"].should == 1
  end

  it "increments each command type" do
    subject.data["commands"]["INCR"].should == 1
    subject.data["commands"]["DECR"].should == 2
  end

  it "keeps track of key accesses" do
    subject.data["keys"]["foo"].should == 2
    subject.data["keys"]["baz"].should == 1
  end

  it "tallies up totals of commands" do
    subject.data["totals"]["all"].should == 5
    subject.data["totals"]["read"].should == 1
    subject.data["totals"]["write"].should == 3
    subject.data["totals"]["other"].should == 1
  end
end

describe Daikon::Monitor, "#parse with new format" do
  subject    { Daikon::Monitor.new }
  let(:line) { '1291699658.994073 "decrby" "fooz" "2000"' }

  it "parses the log into json" do
    subject.parse(line)
    subject.data["commands"]["DECRBY"].should == 1
    subject.data["keys"]["fooz"].should == 1
    subject.data["totals"]["all"].should == 1
    subject.data["totals"]["write"].should == 1
  end
end

describe Daikon::Monitor, "#parse with new format that has reply byte" do
  subject    { Daikon::Monitor.new }
  let(:line) { '+1291699658.994073 "decrby" "fooz" "2000"' }

  it "parses the log into json" do
    subject.parse(line)
    subject.data["commands"]["DECRBY"].should == 1
    subject.data["keys"]["fooz"].should == 1
    subject.data["totals"]["all"].should == 1
    subject.data["totals"]["write"].should == 1
  end
end

describe Daikon::Monitor, "#parse with old multi line input" do
  subject { Daikon::Monitor.new }

  it "parses logs" do
    subject.parse("incr foo")
    subject.parse("sismember project-13897-global-error-classes 17")
    subject.parse("incrApiParameterError")
    subject.parse("decr foo")

    subject.data["commands"]["DECR"].should == 1
    subject.data["commands"]["INCR"].should == 1
    subject.data["commands"]["SISMEMBER"].should == 1
    subject.data["keys"]["foo"].should == 2
    subject.data["keys"]["project-13897-global-error-classes"].should == 1
    subject.data["totals"]["all"].should == 3
    subject.data["totals"]["write"].should == 2
    subject.data["totals"]["read"].should == 1
  end
end

describe Daikon::Monitor, "#parse with old input" do
  subject { Daikon::Monitor.new }

  shared_examples_for "a valid parser" do
    it "parses the given commands properly" do
      subject.data["commands"]["DECR"].should == 1
      subject.data["commands"]["INCR"].should == 1
      subject.data["commands"]["SET"].should == 1
      subject.data["keys"]["foo"].should == 2
      subject.data["keys"]["g:2470920:mrn"].should == 1
      subject.data["totals"]["all"].should == 3
      subject.data["totals"]["write"].should == 3
    end
  end

  context "with a bulk input that is a number" do
    before do
      subject.parse("incr foo")
      subject.parse("set g:2470920:mrn 9")
      subject.parse("554079885")
      subject.parse("decr foo")
    end
    it_should_behave_like "a valid parser"
  end

  context "with a bulk input that is a number" do
    before do
      subject.parse("incr foo")
      subject.parse("set g:2470920:mrn 9")
      subject.parse("46fdcf77c1bb2108e6191602c2f5f9ae")
      subject.parse("decr foo")
    end
    it_should_behave_like "a valid parser"
  end
end
