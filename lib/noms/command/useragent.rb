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

    # This library is for implementing host environment
    # HTTP conversations (so far), not for implementing
    # Javascript-based XMR, the same-origin policy is
    # not important here. In other words, this is how
    # noms initial page is fetched, and script tags
    def get(url, headers={})
        get_url = absolute_url(url)
        @log.debug "GET #{get_url}"
        response = @client.get(get_url, '', headers)
        @log.debug "-> #{response.status} #{response.reason} (#{response.content.size} bytes of #{response.contenttype})"
        response
    end

    # Wait for all asynchronous requests to complete.
    # A stub while these are simulated
    def wait(on=nil)
        []
    end

end
