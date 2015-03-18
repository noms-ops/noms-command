#!ruby

require 'noms/command/version'

require 'noms/command/base'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Window < NOMS::Command::Base

    attr_accessor :document

    def initialize(invoker, opt={})
        @document = nil
        @invoker = invoker
        @log = opt[:logger] || default_logger
    end

    def isatty()
        $stdout.tty?
    end

    def alert(msg)
        @log.error msg
    end

end
