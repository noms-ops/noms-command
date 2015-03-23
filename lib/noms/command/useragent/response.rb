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
            @response.headers[hdr.downcase] unless @response.nil?
        end
    end

    def status
        @response.status.to_i
    end

    def statusText
        @response.status.to_s + ' ' + @response.reason
    end

    def content_type
        @response.contenttype
    end

    def cacheable?
        return false if self.from_cache?
        @cache_control = self.header 'Cache-Control'
        return false if /no-cache/.match @cache_control
        return false if /no-store/.match @cache_contnol
    end

    def from_cache?
        false
    end

end
