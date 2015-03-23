#!ruby

require 'noms/command/version'

require 'time'

require 'noms/command/base'
require 'noms/command/error'
require 'noms/command/useragent'
require 'noms/command/useragent/response'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response < NOMS::Command::Base

    attr_reader :expires, :cache_control, :etag, :last_modified, :date
    attr_accessor :auth_hash, :from_cache

    def self.from_cache(cache_text, opts={})
        unless cache_text.nil? or cache_text.empty?
            self.from_json(cache_text, opts)
        end
    end

    def self.from_json(json_text, opts={})
        return self.new(JSON.parse(json_text), opts)
    end

    # Constructor, pass in HTTP response subclass object
    # In the base clase (which is what gets unfrozen)
    # This is a hash.
    def initialize(httpresponse, opts={})
        @log = opts[:logger] || default_logger
        @log.debug "Creating response from #{httpresponse.inspect}"
        @response = httpresponse
        self.from_cache = false
        self.auth_hash = nil

        if httpresponse.respond_to? :[]
            @log.debug "Created from hash, setting from_cache = #{httpresponse['from_cache'].inspect}"
            self.from_cache = httpresponse['from_cache']
            self.auth_hash = httpresponse['auth_hash']
        end

        @log.debug "self.from_cache? == #{self.from_cache?}"

        @cache_control = self.header 'Cache-Control'
        @expires = get_expires
        @etag = self.header 'Etag'
        @last_modified = get_header_time 'Last-modified'
        @date = get_header_time('Date') || Time.now
    end

    # The response body
    def body
        @response['body']
    end

    # The success status
    def success?
        @response['success?']
    end

    def headercase(s)
        s.split('-').map { |w| w.downcase.capitalize }.join('-')
    end

    # A hash or headers, or specific header
    def header(hdr=nil)
        if hdr.nil?
            @response['header']
        else
            @response['header'][headercase(hdr)] unless @response.nil?
        end
    end

    # An integer status code
    def status
        @response['status']
    end

    # The status message including code
    def statusText
        @response['statusText']
        @response.status.to_s + ' ' + @response.reason
    end

    # MIME Type of content
    def content_type
        self.header 'Content-Type'
    end

    def to_json
        self.to_hash.to_json
    end

    def to_cache
        self.to_json
    end

    def to_hash
        {
            'body' => self.body,
            'header' => self.header,
            'status' => self.status,
            'statusText' => self.statusText,
            'auth_hash' => self.auth_hash,
            'from_cache' => self.from_cache
        }
    end

    def auth_hash=(hvalue)
        @auth_hash = hvalue
    end

    def get_expires
        @log.debug "Extracting expires: Expires=#{self.header('Expires').inspect} " +
            "Cache-Control=#{self.header('Cache-Control').inspect}"
        if @cache_control and (m = /max-age=(\d+)/.match(@cache_control))
            Time.now + m[1].to_i
        elsif @response.header('Expires')
            begin
                Time.httpdate @response.header('Expires')
            rescue ArgumentError => e
                @log.debug "Response had 'Expires' header but could not parse (#{e.class}): #{e.message}"
            end
        end
    end

    def get_header_time(hdr)
        value = self.header hdr
        if value
            begin
                Time.httpdate(value)
            rescue ArgumentError => e
                @log.debug "Response has a '#{hdr}' but could not parse (#{e.class}): #{e.message}"
            end
        end
    end


    def cacheable?
        @log.debug "   (cacheable? checking response code)"
        return false unless @response.code == 200
        @log.debug "   (cacheable? checking for cache info in headers)"
        return false unless @expires
        @log.debug "   (cacheable? checking for if alreday cached response)"
        return false if self.from_cache?
        @log.debug "   (cacheable? checking for no-cache)"
        return false if /no-cache/.match @cache_control
        @log.debug "   (cacheable? checking for no-store)"
        return false if /no-store/.match @cache_control
        @log.debug "   (cacheable? checking for Pragma: no-cache"
        return false if self.header 'Pragma' and /no-cache/.match self.header('Pragma')
        @log.debug "   (cacheable? request is cacheable)"

        true
    end

    def cached!
        @from_cache = true
    end

    def from_cache?
        @from_cache
    end

    def current?
        @log.debug "   (current? checking /must-revalidate/ vs #{@cache_control.inspect})"
        return false if (@cache_control and /must-revalidate/.match @cache_control)
        @log.debug "   (current? checking for cache info [expires = #{@expires.inspect}])"
        return false unless @expires
        @log.debug "   (current? checking #{Time.now} vs expired = #{@expires.inspect} (#{Time.now > @expires}))"
        return false if Time.now > @expires
        true
    end

    def age
        Time.now - @date
    end

    def cacheable_copy
        other = self.dup
        other.logger = nil
        other
    end

end
