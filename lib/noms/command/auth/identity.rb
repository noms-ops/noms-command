#!ruby

require 'logger'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Auth

end

class NOMS::Command::Auth::Identity
    include Enumerable

    def initialize(auth, h, attrs={})
        if attrs[:logger]
            @log = attrs[:logger]
        else
            @log = Logger.new($stderr)
            @log.level = Logger::WARN
            @log.level = Logger::DEBUG if ENV['NOMS_DEBUG']
        end
        @auth = auth
        @data = h
    end

    def [](key)
        @data[key]
    end

    def []=(key, value)
        @data[key] = value
    end

    def each
        @data.each
    end

    def keys
        @data.keys
    end

    def save
        @log.debug "Saving #{@data['id']}"
    end

    def id
        @data['id']
    end

    def realm
        @data['realm']
    end

    def domain
        @data['domain']
    end

    def to_s
        "#{@data['id']}"
    end

end
