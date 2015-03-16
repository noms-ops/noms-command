#!/usr/bin/env

require 'noms/command/urinion'
require 'noms/command/useragent'
require 'noms/command/error'

require 'httpclient'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::XMLHttpRequest

    OPENED = 1
    HEADERS_RECEIVED = 2
    LOADING = 3
    DONE = 4

    @@origin = nil
    @@ua = nil

    def self.origin
        @@origin
    end

    def self.origin=(origin)
        @@origin = NOMS::Command::URInion.parse(origin)
    end

    # We want to be re-using the useragent here because
    # it's the one with the volatile cookies and that
    # already prompted for passwords and stuff.
    def self.useragent
        @@ua
    end

    def self.useragent=(ua)
        @@ua = ua
    end

    attr_accessor :readyState, :responseText, :headers

    def initialize()
        @origin = @@origin
        @ua = @@ua || NOMS::Command::UserAgent.new(@origin)
        @headers = { }
        @readyState = 0
    end

    def same_origin?(other)
        other = NOMS::Command::URInion.parse(other)
        return false unless @origin.scheme == other.scheme
        return false unless @origin.host == other.host
        return false unless @origin.port == other.port
        return true
    end

    def open(method, url, async=true, user=nil, password=nil)
        raise NOMS::Command::Error.new "origin of #{url} doesn't match application origin (#{@origin})" unless
            same_origin? url
        @readyState = 0
        @responseText = ''
        @method = method
        @url = url
        @async = async
        @user = user
        @password = password
    end

    def setRequestHeader(header, value)
        @headers[header] = value
    end

    def OPENED
        OPENED
    end

    def HEADERS_RECEIVED
       HEADERS_RECEIVED
    end

    def LOADING
        LOADING
    end

    def DONE
        DONE
    end

    def send(data=nil)
        case @method
        when 'GET'
            response = @ua.get(@url, @headers)
            if HTTP::Status.successful? response.status
                @readyState = DONE
                @responseText = response.content
            else
                # Some kind of error? No?
                @responseText = ''
                @readyState = DONE
            end
        else
            raise NOMS::Command::Error.new "Method '#{@method}' not understood"
        end
    end

end
