#!ruby

require 'trollop'

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
    end

    def run
        # Find my own configuration for bookmarks and stuff
        # Interpret either environment variables or (maybe) initial options
        parser = Trollop::Parser.new do
            version NOMS::Command::VERSION
            banner <<-USAGE.gsub(/^\s{16}/,'')
                Usage:
                    noms [noms-options] { login | logout | bookmark | url } [options] [arguments]
                    noms-options:
            USAGE
            opt :bookmarks, "Bookmark file location",
                :type => :string,
                :short => '-b',
                :multi => true
            stop_on_unknown
        end

        @opt = Trollop::with_standard_exception_handling parser do
            raise Trollop::HelpNeeded if @argv.empty?
            parser.parse @argv
        end

        if @opt[:bookmarks].empty?
            @opt[:bookmarks] = [ '~/.noms/bookmarks.json',
                '/usr/local/etc/noms/bookmarks.json',
                '/etc/noms/bookmarks.json']
        end

        window = NOMS::Command::Window.new($0)
        origin = @argv[0]
        app = NOMS::Command::Application.new(window, origin, @argv)
        app.fetch!                    # Retrieve page
        app.render!                   # Run scripts
        out = app.display
        puts out unless out.empty?
        app.exitcode                  # Return exitcode
    end

end
