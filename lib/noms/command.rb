#!ruby

require 'trollop'
require 'logger'

require 'noms/command/version'
require 'noms/command/window'
require 'noms/command/application'
require 'noms/command/formatter'

class NOMS

end

class NOMS::Command

    def self.run(argv)
        runner = self.new(argv)
        runner.run
    end

    def initialize(argv)
        @argv = argv
        @log = Logger.new($stderr)
        @log.formatter = lambda { |sev, timestamp, prog, msg| msg[-1].chr == "\n" ? msg : msg + "\n" }
    end

    def run
        # Find my own configuration for bookmarks and stuff
        # Interpret either environment variables or (maybe) initial options
        parser = Trollop::Parser.new do
            version NOMS::Command::VERSION
            banner <<-USAGE.gsub(/^\s{16}/,'')
                Usage:
                  noms [noms-options] { bookmark | url } [options] [arguments]
                  noms-options:
            USAGE
            opt :debug, "Enable debug output"
            opt :verbose, "Enable verbose output"
            opt :nodefault_bookmarks, "Don't consult default bookmarks files",
                :short => 'X',
                :long => '--nodefault-bookmarks'
            opt :bookmarks, "Bookmark file location (can be specified multiple times)",
                :type => :string,
                :multi => true
            stop_on_unknown
        end

        @opt = Trollop::with_standard_exception_handling parser do
            raise Trollop::HelpNeeded if @argv.empty?
            parser.parse @argv
        end

        @opt[:debug] = true if ENV['NOMS_DEBUG'] and ! ENV['NOMS_DEBUG'].empty?

        default_bookmarks =
            [ File.join(ENV['HOME'], '.noms/bookmarks.json'),
            '/usr/local/etc/noms/bookmarks.json',
            '/etc/noms/bookmarks.json'].select { |f| File.exist? f }

        @opt[:bookmarks].concat default_bookmarks unless @opt[:nodefault_bookmarks]

        @log.level = Logger::WARN
        @log.level = Logger::INFO if @opt[:verbose]
        @log.level = Logger::DEBUG if @opt[:debug]

        @bookmark = @opt[:bookmarks].map do |file|
            begin
                File.open(file, 'r') { |fh| JSON.load fh }
            rescue JSON::ParserError => j
                @log.warn "Couldn't load bookmarks from invalid JSON file #{file.inspect}"
                @log.debug "JSON error: #{file.inspect}:#{j.message}"
                nil
            rescue StandardError => e
                @log.warn "Couldn't open #{file.inspect} (#{e.class}): #{e.message}"
                @log.debug "Error opening #{file.inspect}: #{e.backtrace.join("\n")}"
                nil
            end
        end.compact.reverse.inject({}) { |h1, h2| h1.merge h2 }

        begin
            window = NOMS::Command::Window.new($0, :logger => @log)
            origin = @bookmark[@argv[0].split('/').first] || @argv[0]
            app = NOMS::Command::Application.new(window, origin, @argv, :logger => @log)
            app.fetch!                    # Retrieve page
            app.render!                   # Run scripts
            out = app.display
            puts out unless out.empty?
            app.exitcode                  # Return exitcode
        rescue NOMS::Command::Error => e
            @log.error "noms error: #{e.message}"
            255
        end
    end

end
