#!ruby

require 'httpclient'
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
    end

    # This library is for implementing host environment
    # HTTP conversations (so far), not for implementing
    # Javascript-based XMR, the same-origin policy is
    # not important here. In other words, this is how
    # noms initial page is fetched, and script tags
    def get(url)
        @client.request(:get, url)
    end

end
