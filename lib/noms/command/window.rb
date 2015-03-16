class NOMS

end

class NOMS::Command

end

class NOMS::Command::Window

    def initialize(invoker)
        @invoker = invoker
    end

    def isatty
        $stdout.tty?
    end

end
