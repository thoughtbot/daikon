require 'spec_helper'

describe Daikon::Monitor, ".pop without summaries" do
  it "clears out current summaries" do
    Daikon::Monitor.pop do |summary|
      summary["commands"].size.should be_zero
      summary["totals"].size.should be_zero
      summary["keys"].size.should be_zero
    end
  end
end

describe Daikon::Monitor, ".pop with summaries" do
  before do
    parse("INCR foo")
    parse("DECR foo")
    parse("DECR baz")
    parse("HGETALL faz")
    parse("PING")
  end

  it "only saves the top 100 key listings" do
    150.times { |n| parse("INCR foo#{n}") }
    150.times { |n| parse("DECR foo#{n}") }
    100.times { |n| parse("DEL foo#{n}") }

    Daikon::Monitor.pop do |summary|
      summary["keys"].size.should == 100
      summary["keys"].values.all? { |n| n == 3 }.should be_true
    end
  end

  it "santizes key names" do
    parse("INCR $foo.zomg")

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
  before do
    parse('1291699658.994073 "decrby" "fooz" "2000"')
  end

  it "parses the log into json" do
    Daikon::Monitor.pop do |summary|
      summary["commands"]["DECRBY"].should == 1
      summary["keys"]["fooz"].should == 1
      summary["totals"]["all"].should == 1
      summary["totals"]["write"].should == 1
    end
  end
end

describe Daikon::Monitor, "#parse with new format that has reply byte" do
  before do
    parse('+1291699658.994073 "decrby" "fooz" "2000"')
  end

  it "parses the log into json" do
    Daikon::Monitor.pop do |summary|
      summary["commands"]["DECRBY"].should == 1
      summary["keys"]["fooz"].should == 1
      summary["totals"]["all"].should == 1
      summary["totals"]["write"].should == 1
    end
  end
end

describe Daikon::Monitor, "#parse with old multi line input" do
  before do
    parse("incr foo")
    parse("sismember project-13897-global-error-classes 17")
    parse("incrApiParameterError")
    parse("decr foo")
  end

  it "parses logs" do
    Daikon::Monitor.pop do |summary|
      summary["commands"]["DECR"].should == 1
      summary["commands"]["INCR"].should == 1
      summary["commands"]["SISMEMBER"].should == 1
      summary["keys"]["foo"].should == 2
      summary["keys"]["project-13897-global-error-classes"].should == 1
      summary["totals"]["all"].should == 3
      summary["totals"]["write"].should == 2
      summary["totals"]["read"].should == 1
    end
  end
end

describe Daikon::Monitor, "#parse with old input" do
  shared_examples_for "a valid parser" do
    it "parses the given commands properly" do
      Daikon::Monitor.pop do |summary|
        summary["commands"]["DECR"].should == 1
        summary["commands"]["INCR"].should == 1
        summary["commands"]["SET"].should == 1
        summary["keys"]["foo"].should == 2
        summary["keys"]["g:2470920:mrn"].should == 1
        summary["totals"]["all"].should == 3
        summary["totals"]["write"].should == 3
      end
    end
  end

  context "with a bulk input that is a number" do
    before do
      parse("incr foo")
      parse("set g:2470920:mrn 9")
      parse("554079885")
      parse("decr foo")
    end
    it_should_behave_like "a valid parser"
  end

  context "with a bulk input that is a number" do
    before do
      parse("incr foo")
      parse("set g:2470920:mrn 9")
      parse("46fdcf77c1bb2108e6191602c2f5f9ae")
      parse("decr foo")
    end
    it_should_behave_like "a valid parser"
  end
end

describe Daikon::Monitor, "#parse with a bad command name" do
  it "does not save command" do
    parse("gmail foo")
    Daikon::Monitor.pop do |summary|
      summary["commands"].size.should be_zero
    end
  end
end

describe Daikon::Monitor, "#parse with namespaces" do
  before do
    parse("set g:2470920:mrn 9")
    parse("get g:2470914:mrn")
    parse("incr s3-queue-key")
    parse("info")
    parse("decr somehorriblynamespacedkey")
    parse("flushdb")
  end

  it "keeps track of namespace accesses" do
    Daikon::Monitor.pop do |summary|
      summary["namespaces"]["g"].should == 2
      summary["namespaces"]["global"].should == 3
      summary["namespaces"]["s3"].should == 1
    end
  end
end

describe Daikon::Monitor, "#parse with values that have spaces" do
  before do
    parse("set g:2470920:mrn 11")
    parse("Email Error")
  end

  it "counts them properly" do
    Daikon::Monitor.pop do |summary|
      summary["commands"].should   == {"SET" => 1}
      summary["keys"].should       == {"g:2470920:mrn" => 1}
      summary["namespaces"].should == {"g" => 1}
    end
  end
end

describe Daikon::Monitor, "#parse over several minutes keeps several minutes of data" do
  before do
    Timecop.freeze(Time.at(Time.now - 179)) do
      parse("INCR foo")
    end

    Timecop.freeze(Time.at(Time.now - 119)) do
      parse("DECR foo")
    end

    Timecop.freeze(Time.at(Time.now - 60)) do
      parse("INCR foo")
    end
  end

  it "separates each into a separate minute" do
    Daikon::Monitor.pop do |summary|
      summary["commands"].should   == {"INCR" => 1}
      summary["keys"].should       == {"foo" => 1}
    end

    Daikon::Monitor.pop do |summary|
      summary["commands"].should   == {"DECR" => 1}
      summary["keys"].should       == {"foo" => 1}
    end

    Daikon::Monitor.pop do |summary|
      summary["commands"].should   == {"INCR" => 1}
      summary["keys"].should       == {"foo" => 1}
    end
  end
end

describe Daikon::Monitor, "#parse multiple database log" do
  it "parses the data correctly" do
    parse('1304626114.869421 (db 2) "rpop" "shoppinshoppinshoppinshoppinshoppingggggshopping"')

    Daikon::Monitor.pop do |summary|
      summary["commands"].should     == {"RPOP" => 1}
      summary["keys"].should         == {"shoppinshoppinshoppinshoppinshoppingggggshopping" => 1}
    end
  end
end

describe Daikon::Monitor, ".start" do
  let(:redis) { stub('redis', :monitor => true) }
  before do
    redis.stubs(:on).with(:monitor).yields("INCR foo")
  end
  it "should subscribe to monitor" do
    Daikon::Monitor.start(redis)
    redis.should have_received(:monitor)
    redis.should have_received(:on).with(:monitor)
  end

  it "should parse subscription data" do
    Daikon::Monitor.start(redis)
    Daikon::Monitor.pop do |summary|
      summary["commands"].should == {"INCR" => 1}
      summary["keys"].should == {"foo" => 1 }
    end
  end
end
