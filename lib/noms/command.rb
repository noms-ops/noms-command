#!ruby

require 'noms/command/version'
require 'noms/command/home'

require 'trollop'
require 'logger'

require 'noms/command/base'
require 'noms/command/useragent'

require 'noms/command/window'
require 'noms/command/xmlhttprequest'
require 'noms/command/document'

require 'noms/command/application'
require 'noms/command/formatter'
require 'noms/command/auth'
require 'noms/command/auth/identity'

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
        @log.formatter = lambda { |sev, timestamp, prog, msg| (msg.empty? or msg[-1].chr != "\n") ? msg + "\n" : msg }
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
            opt :identity, "Identity file", :short => '-i',
                                            :type => :string,
                                            :multi => true
            opt :logout,   "Log out of authentication sessions", :short => '-L'
            opt :verbose,  "Enable verbose output", :short => '-v'
            opt :list,     "List bookmarks", :short => '-l'
            opt :bookmarks, "Bookmark file location (can be specified multiple times)",
                :short => '-b',
                :type => :string,
                :multi => true
            opt :home,    "Use directory as NOMS_HOME instead of #{NOMS::Command.home}",
                :short => '-H',
                :type => :string
            opt :nocache,  "Don't cache files",
                :short => '-C'
            opt :nodefault_bookmarks, "Don't consult default bookmarks files",
                :short => '-X',
                :long => '--nodefault-bookmarks'
            opt :debug,    "Enable debug output", :short => '-d'
            opt :'plaintext-identity', "Save identity credentials in plaintext", :short => '-P'
            stop_on_unknown
        end

        @opt = Trollop::with_standard_exception_handling parser do
            parser.parse(@argv)
        end

        NOMS::Command.home = @opt[:home] if @opt[:home]

        Trollop::with_standard_exception_handling parser do
            raise Trollop::HelpNeeded if @argv.empty? and ! @opt[:list] and ! @opt[:logout]
        end

        @opt[:debug] = true if ENV['NOMS_DEBUG'] and ! ENV['NOMS_DEBUG'].empty?

        default_bookmarks =
            [ File.join(NOMS::Command.home, 'bookmarks.json'),
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

        if @opt[:list]
            puts @bookmark.map { |pair| '%-15s -> %s' % pair }
            return 0
        end

        if @opt[:logout]
            File.unlink NOMS::Command::Auth::Identity.vault_keyfile if
                File.exist? NOMS::Command::Auth::Identity.vault_keyfile
            return 0
        end

        begin
            origin = @bookmark[@argv[0].split('/').first] || @argv[0]
            app = NOMS::Command::Application.new(origin, @argv, :logger => @log,
                                                 :specified_identities => @opt[:identity],
                                                 :cache => ! @opt[:nocache],
                                                 :plaintext_identity => @opt[:'plaintext-identity'])
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
