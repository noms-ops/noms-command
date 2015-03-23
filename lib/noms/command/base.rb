#!ruby

require 'logger'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Base

    attr_accessor :logger

    def logger
        @log
    end

    def logger=(new_logger)
        @log = new_logger
    end

    def default_logger
        log = Logger.new $stderr
        log.level = Logger::WARN
        log.level = Logger::DEBUG if ENV['NOMS_DEBUG']
        log
    end

end
