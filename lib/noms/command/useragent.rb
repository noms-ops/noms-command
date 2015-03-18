#!ruby

require 'httpclient'
require 'uri'
require 'logger'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent

    def initialize(origin, attrs={})
        @origin = origin
        @client = HTTPClient.new
        if attrs[:logger]
            @log = attrs[:logger]
        else
            @log = Logger.new($stderr)
            @log.level = Logger::WARN
        end
        # Set cookie jar to something origin-specific
        # Set user-agent to something nomsy
        # auth stuff
        # respond to 403 forbidden with prompting and
        # caching
    end

    def absolute_url(url)
        begin
            url = URI.parse url unless url.respond_to? :scheme
            url = URI.join(@origin, url) unless url.absolute?
            url
        rescue StandardError => e
            raise NOMS::Command::Error.new "Error parsing URL #{url} in context of #{@origin} (#{e.class}): #{e.message}"
        end
    end

    def request(method, url, data=nil, headers={})
        req_url = absolute_url(url)
        @log.debug "#{method} #{req_url}" + (headers.empty? ? '' : headers.inspect)
        response = @client.request(method.to_s.upcase, req_url, '', data, headers)
        @log.debug "-> #{response.status} #{response.reason} (#{response.content.size} bytes of #{response.contenttype})"
        response
    end

    def get(url, headers={})
        request('GET', url, nil, headers)
    end

    # Wait for all asynchronous requests to complete.
    # A stub while these are simulated
    def wait(on=nil)
        []
    end

end
