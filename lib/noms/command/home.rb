#!ruby

require 'noms/command/version'

class NOMS

end

class NOMS::Command

    @@home = (ENV.has_key?('NOMS_HOME') and ! ENV['NOMS_HOME'].empty?) ? ENV['NOMS_HOME'] : File.join(ENV['HOME'], '.noms')

    def self.home=(value)
        @@home = value
    end

    def self.home
        @@home
    end

end
