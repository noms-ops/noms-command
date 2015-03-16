#!ruby

require 'noms/command/version'
require 'noms/command/window'
require 'noms/command/document'
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
            doc = NOMS::Command::Document.new(window, origin, argv)
            doc.fetch!                    # Retrieve page
            doc.render!                   # Run scripts
            puts doc.display              # Display result
            doc.exitcode                  # Return exitcode
        end
    end

    def self.usage(cmd)
        <<-USAGE.gsub(/^\s{8}/,'')
        Usage:
            #{cmd} { login | logout | bookmark | url } [options] [arguments]
        USAGE
    end

end
