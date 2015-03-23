#!ruby

require 'noms/command/version'

require 'openssl'
require 'httpclient'
require 'uri'
require 'highline/import'

require 'noms/command/auth'
require 'noms/command/base'
require 'noms/command/useragent/requester'
require 'noms/command/useragent/response'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

    def initialize(origin, attrs={})
        @origin = origin
        # httpclient
        # TODO Replace with TOFU implementation
        @log = attrs[:logger] || default_logger
        @log.debug "Creating useragent with origin #{origin}"
        @client = NOMS::Command::UserAgent::Requester.new :logger => @log
        @log.debug "Created!"
        @redirect_checks = [ ]
        @plaintext_identity = attrs[:plaintext_identity] || false

        @log.debug "(UserAgent) specified identities = #{attrs[:specified_identities]}"
        @auth = NOMS::Command::Auth.new(:logger => @log,
                                        :specified_identities => (attrs[:specified_identities] || []))
    end

    def auth
        @auth
    end

    def check_redirect(url)
        @log.debug "Running #{@redirect_checks.size} redirect checks on #{url}" unless @redirect_checks.empty?
        @redirect_checks.all? { |check| check.call(url) }
    end

    def origin=(new_origin)
        @log.debug "Setting my origin to #{new_origin}"
        @origin = new_origin
    end

    def absolute_url(url)
        @log.debug "Calculating absolute url of #{url} in context of #{@origin}"
        begin
            url = URI.parse url unless url.respond_to? :scheme
            url = URI.join(@origin, url) unless url.absolute?
            url
        rescue StandardError => e
            raise NOMS::Command::Error.new "Error parsing URL #{url} in context of #{@origin} (#{e.class}): #{e.message}"
        end
    end

    def request(method, url, data=nil, headers={}, tries=10, identity=nil)
        req_url = absolute_url(url)
        @log.debug "#{method} #{req_url}" + (headers.empty? ? '' : headers.inspect)
        # httpclient
        begin
            response = @client.request :method => method,
                                       :url => req_url,
                                       :body => data,
                                       :headers => headers
        rescue StandardError => e
            @log.debug e.backtrace.join("\n")
            raise NOMS::Command::Error.new "Couldn't retrieve #{req_url} (#{e.class}): #{e.message})"
        end
        @log.debug "-> #{response.statusText} (#{response.body.size} bytes of #{response.content_type})"
        @log.debug JSON.pretty_generate(response.header)
        case response.status
        when 401
            @log.debug "   handling unauthorized"
            if identity
                # The identity we got was no good, try again
                @log.debug "   we have an identity #{identity['username']} @ #{identity} but are trying again"
                identity.clear
                if tries > 0
                    identity = @auth.load(url, response)
                    # httpclient
                    @client.set_auth(identity['domain'], identity['username'], identity['password'])
                    response, req_url = self.request(method, url, data, headers, tries - 1, identity)
                end
            else
                identity = @auth.load(url, response)
                # httpclient
                @client.set_auth(identity['domain'], identity['username'], identity['password'])
                response, req_url = self.request(method, url, data, headers, 2, identity)
            end
            identity = nil
        when 302, 301
            new_url = response.header('Location')
            if check_redirect new_url
                @log.debug "redirect to #{new_url}"
                raise NOMS::Command::Error.new "Can't follow redirect to #{new_url}: too many redirects" if tries <= 0
                response, req_url = self.request(method, new_url, data, headers, tries - 1)
            end
        end

        if identity and response.success?
            @log.debug "Login succeeded, saving #{identity['username']} @ #{identity}"
            identity.save :encrypt => (! @plaintext_identity)
        end

        @log.debug "<- #{response.statusText} <- #{req_url}"
        [response, req_url]
    end

    def get(url, headers={})
        request('GET', url, nil, headers)
    end

    # Wait for all asynchronous requests to complete.
    # A stub while these are simulated
    def wait(on=nil)
        []
    end

    def add_redirect_check(&block)
        @log.debug "Adding #{block} to redirect checks"
        @redirect_checks << block
    end

    def clear_redirect_checks
        @log.debug "Clearing redirect checks"
        @redirect_checks = [ ]
    end

    def pop_redirect_check
        unless @redirect_checks.empty?
            @log.debug "Popping redirect check: #{@redirect_checks[-1]}"
            @redirect_checks.pop
        end
    end
end
