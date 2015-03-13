#!ruby

require 'noms/command/version'
require 'noms/command/window'
require 'noms/command/useragent'

require 'uri'
require 'logger'
require 'mime-types'
require 'httpclient'
require 'httpclient'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Document

    # Should user-agent actually be here?
    attr_accessor :window, :argv, :options,
        :exitcode, :type, :body, :useragent


    def initialize(window, origin, argv, attrs={})
        @window = window             # A NOMS::Command::Window
        @origin = URI.parse(origin)
        if @origin.scheme == 'file' and @origin.host.nil?
            @origin.host = 'localhost'
        end
        @exitcode = 0
        @argv = argv
        @options = { }
        @type = nil
        @log = attrs[:logger] || Logger.new($stderr)
        @log.level = attrs[:loglevel] || Logger::WARN
        @useragent = NOMS::Command::UserAgent.new(@origin, :logger => @log)
    end

    def fetch!
        # Get content and build object, set @type
        case @origin.scheme
        when 'file'
            @type = (MIME::Types.of(@origin.path).first || MIME::Types['text/plain'].first).content_type
            @body = File.open(@origin.path, 'r') { |fh| fh.read }
        when /^http/
            @log.debug "Document: requesting @origin.inspect"
            response = @useragent.get(@origin)
            if HTTP::Status.successful? response.status
                # Unlike typical ReST data sources, this
                # should very rarely fail unless there is
                # a legitimate communication issue.
                @type = response.contenttype || 'text/plain'
                @body = response.content
            else
                raise NOMS::Command::Error.new("Failed to request #{@origin}: #{response.status} #{response.reason}")
            end
        else
            raise NOMS::Command::Error.new("Can't retrieve a '#{scheme}' url (#{@origin})")
        end

        case @type
        when /^(application|text)\/(x-|)json/
            @body = JSON.parse(@body)
            if @body.has_key? '$doctype'
                @type = @body['$doctype']
            end
        end
    end

    def render!
        # Fetch and interpret '$script' tag if any
    end

    def display
        case @type
        when 'noms-v2'
            # @body is an object (with a body attribute)
        when 'noms-raw'
        when /^text(\/|$)/
            @body
        else
            if @window.isatty
                @log.warn "Unknown data of type '#{@type}' not sent to terminal"
            else
                @body
            end
        end
    end

end
