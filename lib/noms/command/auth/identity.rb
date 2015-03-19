#!ruby

require 'noms/command/version'

require 'fileutils'
require 'logger'

require 'noms/command/base'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Auth < NOMS::Command::Base

end

class NOMS::Command::Auth::Identity < NOMS::Command::Base
    include Enumerable

    @@identity_dir = File.join(ENV['HOME'], '.noms', 'identities')

    def initialize(auth, h, attrs={})
        @log = attrs[:logger] || default_logger
        @auth = auth
        @data = h
        @max_key_idle = 4 * 3600
    end

    def ensure_dir
        unless File.directory? @@identity_dir
            FileUtils.mkdir_p @@identity_dir
        end
        File.chmod 0600, @@identity_dir
    end

    def renew_vault_key
        vault_keyfile = File.join(@@identity_dir, '.noms-vault-key')
        if File.exist? vault_keyfile
            File.utime(Time.now, Time.now, vault_keyfile)
        end
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

    def clean
        @log.debug "Clearing #{@data['id']}"
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
        @data['id']
    end

end
