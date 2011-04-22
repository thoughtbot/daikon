module ParseHelper
  def parse(line)
    Daikon::Monitor.parse(line)
  end
end
