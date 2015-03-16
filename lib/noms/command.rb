#!ruby

require 'noms/command/version'
require 'noms/command/window'
require 'noms/command/application'
require 'noms/command/formatter'

class NOMS

end

class NOMS::Command

    def self.run(argv)
        # Find my own configuration for bookmarks and stuff
        # Interpret either environment variables or (maybe) initial options
        if argv.empty?
            puts self.usage('noms2')
            2
        else
            window = NOMS::Command::Window.new($0)
            origin = argv.shift
            app = NOMS::Command::Application.new(window, origin, argv)
            app.fetch!                    # Retrieve page
            app.render!                   # Run scripts
            puts app.display              # Display result
            app.exitcode                  # Return exitcode
        end
    end

    def self.usage(cmd)
        <<-USAGE.gsub(/^\s{8}/,'')
        Usage:
            #{cmd} { login | logout | bookmark | url } [options] [arguments]
        USAGE
    end

end
