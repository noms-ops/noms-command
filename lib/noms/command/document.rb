#!ruby

require 'noms/command/version'
require 'noms/command/window'

require 'uri'
require 'logger'
require 'httpclient'
require 'mime-types'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Document

    attr_accessor :window, :argv, :options, :exitcode, :type, :body

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
    end

    def fetch!
        # Get content and build object, set @type
        case @origin.scheme
        when 'file'
            @type = (MIME::Types.of(@origin.path).first || MIME::Types['text/plain'].first).content_type
            @body = File.open(@origin.path, 'r') { |fh| fh.read }
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
