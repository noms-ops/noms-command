class NOMS

end

class NOMS::Command

end

class NOMS::Command::Window

    attr_accessor :document

    def initialize(invoker)
        @document = nil
        @invoker = invoker
    end

    def isatty
        $stdout.tty?
    end

end
