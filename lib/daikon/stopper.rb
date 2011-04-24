module Daikon
  module Stopper
    attr_writer :stopper

    private

    def stopper
      if @stopper && @stopper.call(self)
        EventMachine.stop
      end
    end
  end
end
