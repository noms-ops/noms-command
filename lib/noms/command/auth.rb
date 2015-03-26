#!ruby

require 'noms/command/version'

require 'httpclient'
require 'etc'
require 'highline'
require 'json'
require 'cgi'

require 'noms/command/base'
require 'noms/command/auth/identity'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Auth < NOMS::Command::Base

    def initialize(opts={})
        @log = opts[:logger] || default_logger
        @specified = { }
        @input  = opts[:prompt_input]  || $stdin
        @output = opts[:prompt_output] || $stdout
        @force_prompt = opts.has_key?(:force_prompt) ? opts[:force_prompt] : false

        (opts[:specified_identities] || []).each do |file|
            maybe_id = NOMS::Command::Auth::Identity.from file
            raise NOMS::Command::Error.now "#{file} contains invalid identity (no 'id')" unless
                maybe_id['id']
            @specified[maybe_id['id']] = maybe_id
        end
    end

    def load(url, response)
        # Prompt
        auth_header = response.header('WWW-Authenticate')
        auth_header = (auth_header.respond_to?(:first) ? auth_header.first : auth_header)
        case auth_header
        when /Basic/
            if m = /realm=\"([^\"]*)\"/.match(auth_header)
                realm = m[1]
            else
                realm = ''
            end
            domain = [url.scheme, '://', url.host, ':', url.port, '/'].join('')
            identity_id = CGI.escape(realm) + '=' + domain
            unless @specified.empty?
                if @specified[identity_id]
                    @specified[identity_id]
                else
                    @log.warn "No identity specified for #{domain} (#{realm})"
                    nil
                end
            else
                if id_info = saved(identity_id)
                    NOMS::Command::Auth::Identity.new(id_info, :logger => @log)
                else
                    # It might be nice to synchronize around this to
                    # make pipelines work.
                    if $stdin.tty? or @force_prompt
                        highline = HighLine.new(@input, @output)
                        default_user = Etc.getlogin
                        prompt = "#{domain} (#{realm}) username: "
                        user = highline.ask(prompt) { |u| u.default = Etc.getlogin }
                        pass = highline.ask('Password: ') { |p| p.echo = false }
                        NOMS::Command::Auth::Identity.new({
                                                              'id' => identity_id,
                                                              'realm' => realm,
                                                              'domain' => domain,
                                                              'username' => user,
                                                              'password' => pass
                                                          }, :logger => @log)
                    else
                        @log.warn "Can't prompt for #{domain} (#{realm}) authentication (not a terminal)"
                        NOMS::Command::Auth::Identity.new({
                                                              'id' => identity_id,
                                                              'realm' => realm,
                                                              'domain' => domain,
                                                              'username' => '',
                                                              'password' => ''
                                                          }, :logger => @log)
                    end
                end
            end
        else
            raise NOMS::Command::Error.new "Authentication not supported: #{auth_header.inspect}"
        end
    end

    def saved(identity_id)
        NOMS::Command::Auth::Identity.saved identity_id
    end

end
