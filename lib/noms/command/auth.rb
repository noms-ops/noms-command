#!ruby

require 'noms/command/version'
require 'httpclient'
require 'etc'
require 'highline/import'
require 'json'
require 'cgi'

require 'noms/command/auth/identity'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Auth

    def initialize(window, opts={})
        @log = opts[:logger] || Logger.new($stderr)
    end

    # TODO: Persistent auth creds
    # Store like a client certificate: encrypted. Then use an
    # agent to store by using <agent>-add and typing passphrase
    # just like a client cert. <agent> expires credentials.
    # also you can explicitly unencrypt identity file

    def load(url, response)
        # Prompt
        auth_header = response.header['www-authenticate']
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
            if saved(identity_id)
                retrieve(identity_id)
            else
                if $stdin.tty?
                    default_user = Etc.getlogin
                    prompt = "#{domain} (#{realm}) username: "
                    user = ask(prompt) { |u| u.default = Etc.getlogin }
                    pass = ask('Password: ') { |p| p.echo = false }
                    NOMS::Command::Auth::Identity.new(self, {
                                                          'id' => identity_id,
                                                          'realm' => realm,
                                                          'domain' => domain,
                                                          'username' => user,
                                                          'password' => pass
                                                      })
                else
                    @log.warn "Can't prompt for #{domain} (#{realm}) authentication (not a terminal)"
                    NOMS::Command::Auth::Identity.new({
                                                         'id' => identity_id,
                                                         'realm' => realm,
                                                         'domain' => domain,
                                                         'username' => '',
                                                         'password' => ''
                                                     })
                end
            end
        else
            raise NOMS::Command::Error.new "Authentication not supported: #{auth_header.inspect}"
        end
    end

    def saved(identity_id)
         nil
    end

    def retrieve(identity_id)
        nil
    end

end
