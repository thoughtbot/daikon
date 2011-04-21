require 'spec_helper'

describe Daikon::Monitor, ".pop without data" do
  it "clears out current data" do
    Daikon::Monitor.pop do |summary|
      summary["commands"].size.should be_zero
      summary["totals"].size.should be_zero
      summary["keys"].size.should be_zero
    end
  end
end

describe Daikon::Monitor, ".pop with data" do
  before do
    subject.parse("INCR foo")
    subject.parse("DECR foo")
    subject.parse("DECR baz")
    subject.parse("HGETALL faz")
    subject.parse("PING")
  end

  it "only saves the top 100 key listings" do
    150.times { |n| subject.parse("INCR foo#{n}") }
    150.times { |n| subject.parse("DECR foo#{n}") }
    100.times { |n| subject.parse("DEL foo#{n}") }

    Daikon::Monitor.pop do |summary|
      summary["keys"].size.should == 100
      summary["keys"].values.all? { |n| n == 3 }.should be_true
    end
  end

  it "santizes key names" do
    subject.parse("INCR $foo.zomg")

    Daikon::Monitor.pop do |summary|
      summary["keys"]["$foo.zomg"].should be_nil
      summary["keys"]["{DOLLAR}foo{PERIOD}zomg"].should == 1
    end
  end

  it "increments each command type" do
    Daikon::Monitor.pop do |summary|
      summary["commands"]["INCR"].should == 1
      summary["commands"]["DECR"].should == 2
    end
  end

  it "keeps track of key accesses" do
    Daikon::Monitor.pop do |summary|
      summary["keys"]["foo"].should == 2
      summary["keys"]["baz"].should == 1
    end
  end

  it "tallies up totals of commands" do
    Daikon::Monitor.pop do |summary|
      summary["totals"]["all"].should == 5
      summary["totals"]["read"].should == 1
      summary["totals"]["write"].should == 3
      summary["totals"]["other"].should == 1
    end
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

describe Daikon::Monitor, "#parse with a bad command name" do
  it "does not save command" do
    subject.parse("gmail foo")
    subject.data["commands"].size.should be_zero
  end
end

describe Daikon::Monitor, "#parse with namespaces" do
  before do
    subject.parse("set g:2470920:mrn 9")
    subject.parse("get g:2470914:mrn")
    subject.parse("incr s3-queue-key")
    subject.parse("info")
    subject.parse("decr somehorriblynamespacedkey")
    subject.parse("flushdb")
  end

  it "keeps track of namespace accesses" do
    subject.data["namespaces"]["g"].should == 2
    subject.data["namespaces"]["global"].should == 3
    subject.data["namespaces"]["s3"].should == 1
  end
end

describe Daikon::Monitor, "#parse with values that have spaces" do
  before do
    subject.parse("set g:2470920:mrn 11")
    subject.parse("Email Error")
  end

  it "counts them properly" do
    subject.data["commands"].should   == {"SET" => 1}
    subject.data["keys"].should       == {"g:2470920:mrn" => 1}
    subject.data["namespaces"].should == {"g" => 1}
  end
end
