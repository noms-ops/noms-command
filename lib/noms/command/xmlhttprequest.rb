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

    attr_accessor :responseText, :headers

    def initialize()
        @origin = @@origin
        @ua = @@ua || NOMS::Command::UserAgent.new(@origin)
        @headers = { }
        @readyState = 0
    end

    def useragent
        @ua
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
            same_origin? @ua.absolute_url(url)
        # Should we run onreadystatechange when resetting this? Not doing it for now.
        @readyState = 0
        @responseText = ''
        @response = nil
        @method = method
        @url = url
        @async = async
        @user = user
        @password = password
    end

    def onreadystatechange
        @onreadystatechange
    end

    def onreadystatechange=(callback)
        @onreadystatechange = callback
    end

    def readyState
        @readyState
    end

    def readyState=(value)
        @readyState = value
        unless @onreadystatechange.nil?
            @onreadystatechange.methodcall self
        end
        @readyState
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

    # Oh, XMLHttpRequest, using send().
    def send(*vary)
        if vary.size == 0 or (vary.size == 1 and ! vary[0].is_a? Symbol)
            do_send(*vary)
        else
            super
        end
    end

    # NOMS::Command::UserAgent doesn't do async
    # calls (yet) since httpclient doesn't do
    # anything special with them and you can
    # only busy-wait on them. So they're "simulated",
    # and by "simulated" I mean "performed synchronously".
    def do_send(data=nil)
        # @async ignored
        @ua.add_redirect_check do |url|
            self.same_origin? url
        end
        @response, landing_url = @ua.request(@method, @url, data, @headers)
        # We don't need the 'landing' URL
        @ua.pop_redirect_check
        self.readyState = OPENED
        self.readyState = HEADERS_RECEIVED
        self.readyState = LOADING
        @responseText = @response.content
        self.readyState = DONE
    end

    def status
        @response.status.to_i unless @response.nil?
    end

    def statusText
        @response.status + ' ' + @response.reason unless @response.nil?
    end

    def getResponseHeader(header)
        @response.header[header.downcase] unless @response.nil?
    end

    def getAllResponseHeaders
        lambda { || @response.headers.map { |h, v| "#{h}: #{v}" }.join("\n") + "\n" }
    end

    def abort()
        lambda { || @readyState = 0 }
    end

end
