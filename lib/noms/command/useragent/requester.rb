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

    def self.new(opts={})
        require 'noms/command/useragent/requester/httpclient'
        NOMS::Command::UserAgent::Requester::HTTPClient.new(opts)
    end

    def initialize(opt={})

    end

    def request(req_attr={})

    end

    def set_auth(domain, user, password)

    end

end
