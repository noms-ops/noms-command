#!/usr/bin/env ruby

require 'noms/command/version'

require 'httpclient'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response::HTTPClient < NOMS::Command::Base

    def initialize(httpresponse, opts={})
        @log = opts[:logger] || default_logger
        @response = httpresponse
    end

    def body
        @response.content
    end

    def success?
        @response.ok?
    end

    def header(hdr=nil)
        if hdr.nil?
            @response.headers
        else
            @response.header[hdr.downcase] unless @response.nil?
        end
    end

    def status
        @response.status.to_i unless @response.status.nil?
    end

    def statusText
        @response.status.to_s + ' ' + @response.reason unless @response.status.nil?
    end

    def content_type
        @response.contenttype
    end

end
