require "noms/command/version"

class NOMS

end

class NOMS::Command

    def self.run(argv)
        # Find my own configuration for bookmarks and stuff
        # Interpret either environment variables or (maybe) initial options
        if argv.empty?
            puts self.usage('noms2')
            2
        end
    end

    def self.usage(cmd)
        <<-USAGE.gsub(/^\s{8}/,'')
        Usage:
            #{cmd} { login | logout | bookmark | url } [options] [arguments]
        USAGE
    end

end
