#!ruby

require 'noms/command/version'

require 'noms/command/base'
require 'noms/command/useragent'
require 'noms/command/useragent/response'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response < NOMS::Command::Base

    def self.new(response, opt={})
        require 'noms/command/useragent/response/httpclient'
        NOMS::Command::UserAgent::Response::HTTPClient.new(response, opt)
    end

end
