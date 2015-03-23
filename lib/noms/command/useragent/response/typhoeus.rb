#!/usr/bin/env ruby

require 'noms/command/version'

require 'typhoeus'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response::Typhoeus < NOMS::Command::Base

    def initialize(httpresponse, opts={})
        @log = opts[:logger] || default_logger
        @response = httpresponse
    end

    def body
        @response.body
    end

    def success?
        @response.success?
    end

    def header(hdr=nil)
        if hdr.nil?
            @response.headers
        else
            @response.headers[hdr]
        end
    end

    def status
        @response.code.to_i
    end

    def statusText
        @response.status_message
    end

    def content_type
        @response.headers['Content-Type']
    end

end
