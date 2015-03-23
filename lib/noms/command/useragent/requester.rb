#!ruby

require 'noms/command/version'

require 'noms/command/base'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Requester < NOMS::Command::Base

    @@requester_class = 'typhoeus'

    def self.new(opts={})
        case @@requester_class
        when 'httpclient'
            require 'noms/command/useragent/requester/httpclient'
            NOMS::Command::UserAgent::Requester::HTTPClient.new(opts)
        when 'typhoeus'
            require 'noms/command/useragent/requester/typhoeus'
            NOMS::Command::UserAgent::Requester::Typhoeus.new(opts)
        else
            raise NOMS::Command::Error.new "Internal error - no requester class #{@@requester_class}"
        end
    end

    def initialize(opt={})

    end

    def request(req_attr={})

    end

    def set_auth(domain, user, password)

    end

end
