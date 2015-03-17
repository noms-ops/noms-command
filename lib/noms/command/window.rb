class NOMS

end

class NOMS::Command

end

class NOMS::Command::Window

    attr_accessor :document

    def initialize(invoker, opt={})
        @document = nil
        @invoker = invoker
        @log = opt[:logger] || Logger.new($stderr)
    end

    def isatty()
        $stdout.tty?
    end

    def alert(msg)
        @log.error msg
    end

end
