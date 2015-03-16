#!ruby

require 'noms/command/version'
require 'noms/command/window'
require 'noms/command/useragent'
require 'noms/command/error'
require 'noms/command/urinion'
require 'noms/command/formatter'

require 'logger'
require 'mime-types'
require 'httpclient'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Application

    # Should user-agent actually be here?
    attr_accessor :window, :argv, :options,
        :exitcode, :type, :body, :useragent


    def initialize(window, origin, argv, attrs={})
        @window = window             # A NOMS::Command::Window
        @origin = NOMS::Command::URInion.parse(origin)
        if @origin.scheme == 'file' and @origin.host.nil?
            @origin.host = 'localhost'
        end
        @exitcode = 0
        @argv = argv
        @options = { }
        @type = nil
        @log = attrs[:logger] || Logger.new($stderr)
        @log.level = attrs[:loglevel] || _default_severity
        @log.debug "Creating application object at origin: #{origin}"
        @useragent = NOMS::Command::UserAgent.new(@origin, :logger => @log)
    end

    def _default_severity
        level = {
            'DEBUG' => Logger::DEBUG,
            'INFO' => Logger::INFO,
            'WARN' => Logger::WARN,
            'ERROR' => Logger::ERROR,
            'FATAL' => Logger::FATAL
        }
        level[ENV['NOMS_LOGLEVEL']] || Logger::WARN
    end

    def fetch!
        # Get content and build object, set @type
        case @origin.scheme
        when 'file'
            @type = (MIME::Types.of(@origin.path).first || MIME::Types['text/plain'].first).content_type
            @body = File.open(@origin.path, 'r') { |fh| fh.read }
        when 'data'
            @type = @origin.mime_type
            raise NOMS::Command::Error.new("data URLs must contain application/json") unless @type == 'application/json'
            @body = @origin.data
        when /^http/
            @log.debug "Application: requesting @origin.inspect"
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
            @log.debug "HTTP body is JSON: #{@body.inspect}"
            if @body.has_key? '$doctype'
                @type = @body['$doctype']
                @log.debug "Treating as #{@type} document"
            else
                @log.debug "Treating as raw object (no '$doctype')"
                @type = 'noms-raw'
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
            # Confusing dual-used of 'body'. @body variable is
            # HTTP response body, basically, and '$body' is
            # document $body attribute.
            NOMS::Command::Formatter.new(@body['$body']).render
        when 'noms-raw'
            @body.to_yaml
        when /^text(\/|$)/
            @body
        else
            if @window.isatty
                # Should this be here?
                @log.warn "Unknown data of type '#{@type}' not sent to terminal"
            else
                @body
            end
        end
    end

end
