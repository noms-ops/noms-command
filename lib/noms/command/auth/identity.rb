#!ruby

require 'noms/command/version'
require 'noms/command/home'

require 'fileutils'
require 'logger'
require 'openssl'
require 'fcntl'
require 'base64'
require 'bcrypt'

require 'noms/command'

class String
    def to_hex
        self.unpack('C*').map { |n| '%02x' % n }.join('')
    end
end

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Auth < NOMS::Command::Base

end

class NOMS::Command::Auth::Identity < NOMS::Command::Base
    include Enumerable

    @@identity_dir = File.join(NOMS::Command.home, 'identities')
    @@cipher       = 'aes-256-cfb'
    @@hmac_digest  = 'sha256'
    @@max_key_idle = 3600

    def self.identity_dir
        @@identity_dir
    end

    def self.identity_dir=(value)
        @@identity_dir = value
    end

    def self.generate_new_key
        cipher = OpenSSL::Cipher.new(@@cipher)
        cipher.encrypt
        cipher.random_key + cipher.random_key
    end

    def self.vault_keyfile
        File.join(@@identity_dir, '.noms-vault-key')
    end

    def self.ensure_dir
        unless File.directory? @@identity_dir
            FileUtils.mkdir_p @@identity_dir
        end
        File.chmod 0700, @@identity_dir
    end

    def self.get_vault_key
        key = ''
        ensure_dir
        fh = File.for_fd(IO.sysopen(vault_keyfile, Fcntl::O_RDWR | Fcntl::O_CREAT, 0600))
        fh.flock(File::LOCK_EX)
        mtime = fh.mtime

        key = fh.read if (Time.now - mtime < @@max_key_idle)

        if key.empty?
            key = generate_new_key
            fh.write key
        end
        fh.flock(File::LOCK_EX)
        fh.close

        key
    end

    def self.decrypt(blob)
        mac_key, enc_key = get_vault_key.unpack('a32a32')

        message = Base64.decode64(blob)
        hmac_digest, iv, data = message.unpack('a32a16a*')

        hmac = OpenSSL::HMAC.new(mac_key, OpenSSL::Digest.new(@@hmac_digest))
        hmac.update(iv + data)
        raise NOMS::Command::Error.new("HMAC verification error") unless hmac.digest == hmac_digest

        cipher = OpenSSL::Cipher.new @@cipher
        cipher.decrypt
        cipher.key = enc_key
        cipher.iv = iv
        cipher.update(data) + cipher.final
    end


    # Returns hash of identity data suitable for passing to .new
    def self.saved(identity_id, opt={})
        # This can't really log errors, hm.
        id_number = OpenSSL::Digest::SHA1.new(identity_id).hexdigest
        file_base = File.join(@@identity_dir, id_number)

        if File.exist? "#{file_base}.json"
            begin
                JSON.parse(File.read "#{file_base}.json").merge({ '_loaded' => { "#{file_base}.json" => Time.now.to_s } })
            rescue StandardError => e
                File.unlink "#{file_base}.json" if File.exist? "#{file_base}.json"
                return nil
            end
        elsif File.exist? "#{file_base}.enc"
            begin
                hash = JSON.parse(decrypt(File.read("#{file_base}.enc"))).
                    merge({ '_decrypted' => true, '_loaded' => { "#{file_base}.enc" => Time.now.to_s } })
            rescue StandardError => e
                File.unlink "#{file_base}.enc" if File.exist? "#{file_base}.enc"
                return nil
            end
        else
            return nil
        end

    end

    def self.from(file)
        begin
            raise NOMS::Command::Error.new "Identity file #{file} does not exist" unless File.exist? file
            s = File.stat file
            raise NOMS::Command::Error.new "You don't own identity file #{file}" unless s.owned?
            raise NOMS::Command::Error.new "Permissions on #{file} are too permissive" unless (s.mode & 077 == 0)
            contents = File.read file
            raise NOMS::Command::Error.new "#{file} is empty" unless contents and ! contents.empty?
            case contents[0].chr
            when '{'
                NOMS::Command::Auth::Identity.new(JSON.parse(contents).merge({'_specified' => file }), :logger => @log)
            else
                raise NOMS::Command::Error.new "#{file} contains unsupported or corrupted data"
            end
        rescue StandardError => e
            if e.is_a? NOMS::Command::Error
                raise e
            else
                raise NOMS::Command::Error.new "Couldn't load identity from #{file} (#{e.class}): #{e.message}"
            end
        end
    end

    def initialize(h, attrs={})
        @log = attrs[:logger] || default_logger
        @data = h
        refresh_vault_key if h['_decrypted']
    end

    def specified
        @data['_specified']
    end

    def verification_hash
        BCrypt::Password.create(self['username'] + ':' + self['password'] + '@' + self['id']).to_s
    end

    def auth_verify?(pwd_hash)
        pwd = BCrypt::Password.new(pwd_hash)
        pwd == self['username'] + ':' + self['password'] + '@' + self['id']
    end

    def id_number
        OpenSSL::Digest::SHA1.new(self['id']).hexdigest
    end

    def [](key)
        @data[key]
    end

    def []=(key, value)
        $stderr.puts "auth identity set #{key} = #{value}"
        @data[key] = value
    end

    def each
        @data.each
    end

    def keys
        @data.keys
    end

    def refresh_vault_key
        vault_keyfile = NOMS::Command::Auth::Identity.vault_keyfile
        if File.exist? vault_keyfile
            File.utime(Time.now, Time.now, vault_keyfile)
        end
    end

    def save(opt={})
        return self.specified if self.specified
        begin
            opt[:encrypt] = true unless opt.has_key? :encrypt
            file = opt[:file] || File.join(@@identity_dir, self.id_number + '.' + (opt[:encrypt] ? 'enc' : 'json'))
            data = opt[:encrypt] ? self.encrypt : (self.to_json + "\n")

            File.open(file, 'w') { |fh| fh.write data }
            file
        rescue StandardError => e
            @log.warn "Couldn't save identity for #{@data['id']} (#{e.class}): #{e.message}"
            @log.debug { e.backtrace.join("\n") }
            return nil
        end
    end

    def clear(opt={})
        @log.debug "Clearing #{@data['id']}"
        begin
            basefile = File.join(@@identity_dir, self.id_number)
            File.unlink "#{basefile}.json" if File.exist? "#{basefile}.json"
            File.unlink "#{basefile}.enc" if File.exist? "#{basefile}.enc"
        end
    end

    def to_json
        @data.to_json
    end

    def encrypt
        mac_key, enc_key = NOMS::Command::Auth::Identity.get_vault_key.unpack('a32a32')
        cipher = OpenSSL::Cipher.new @@cipher
        cipher.encrypt
        iv = cipher.random_iv
        cipher.key = enc_key
        plaintext = self.to_json
        data = cipher.update(plaintext) + cipher.final

        hmac = OpenSSL::HMAC.new(mac_key, OpenSSL::Digest.new(@@hmac_digest))
        hmac.update(iv + data)

        message = hmac.digest + iv + data

        Base64.encode64(message)
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
