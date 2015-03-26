#!ruby

require 'noms/command/version'

require 'time'

require 'noms/command'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response < NOMS::Command::Base

    attr_reader :expires, :cache_control, :etag, :last_modified
    attr_accessor :auth_hash, :from_cache, :date, :original_date

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
        @response = httpresponse
        self.from_cache = false
        self.auth_hash = nil

        if httpresponse.respond_to? :[]
            self.from_cache = httpresponse['from_cache']
            self.auth_hash = httpresponse['auth_hash']
            self.original_date = Time.httpdate(httpresponse['original_date'])
            self.date = Time.httpdate(httpresponse['date'])
        end

        @cache_control = self.header 'Cache-Control'
        @date = get_header_time('Date') || Time.now
        @original_date ||= @date
        @expires = get_expires
        @etag = self.header 'Etag'
        @last_modified = get_header_time 'Last-modified'
    end

    # The response body
    def body
        @response['body']
    end

    # The success status
    def success?
        # We created this object explicitly, so it's always successful
        true
    end

    # A hash or headers, or specific header
    def header(hdr=nil)
        if hdr.nil?
            @response['header']
        else
            Hash[@response['header'].map { |h, v| [h.downcase, v] }][hdr.downcase] unless @response.nil?
        end
    end

    # An integer status code
    def status
        @response['status']
    end

    # The status message including code
    def statusText
        @response['statusText']
    end

    # MIME Type of content
    def content_type
        self.header 'Content-Type'
    end

    def header_params(s)
        Hash[s.split(';').map do |field|
                param, value = field.split('=', 2)
                value ||= ''
                [param.strip, value.strip]
            end]
    end

    def content_encoding
        if self.content_type
            header_params(self.content_type)['charset']
        end
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
            'from_cache' => self.from_cache,
            'date' => self.date.httpdate,
            'original_date' => self.original_date.httpdate
        }
    end

    def auth_hash=(hvalue)
        @auth_hash = hvalue
    end

    def get_expires

        expires = [ ]

        if @cache_control and (m = /max-age=(\d+)/.match(@cache_control))
            expires << (@date + m[1].to_i)
        end

        if self.header('Expires')
            begin
                expires << Time.httpdate(self.header('Expires'))
            rescue ArgumentError => e
                @log.debug "Response had 'Expires' header but could not parse (#{e.class}): #{e.message}"
            end
        end

        return nil if expires.empty?

        expires.empty? ? nil : expires.min
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
        return false unless self.status == 200
        return false unless @expires
        return false if self.from_cache?
        return false if /no-cache/.match @cache_control
        return false if /no-store/.match @cache_control
        return false if self.header 'Pragma' and /no-cache/.match self.header('Pragma')

        true
    end

    def cached!
        @from_cache = true
    end

    def from_cache?
        @from_cache
    end

    def current?
        return false if (@cache_control and /must-revalidate/.match @cache_control)
        return false unless @expires
        return false if Time.now > @expires
        true
    end

    def age
        Time.now - self.original_date
    end

    def cacheable_copy
        other = self.dup
        other.logger = nil
        other
    end

end
