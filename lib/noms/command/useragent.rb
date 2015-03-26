#!ruby

require 'noms/command/version'

require 'openssl'
require 'httpclient'
require 'uri'
require 'highline/import'

require 'noms/command'
require 'noms/command/useragent/cache'
require 'noms/command/useragent/requester'
require 'noms/command/useragent/response'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

    attr_accessor :cache, :cacher, :auth

    def initialize(origin, attrs={})
        @origin = origin.respond_to?(:scheme) ? origin : URI.parse(origin)
        # httpclient
        # TODO Replace with TOFU implementation
        @log = attrs[:logger] || default_logger
        cookies = attrs.has_key?(:cookies) ? attrs[:cookies] : true

        @client = NOMS::Command::UserAgent::Requester.new :logger => @log, :cookies => cookies

        @redirect_checks = [ ]
        @plaintext_identity = attrs[:plaintext_identity] || false

        @cache = attrs.has_key?(:cache) ? attrs[:cache] : true
        @max_age = attrs[:max_age] || 3600

        if @cache
            @cacher = NOMS::Command::UserAgent::Cache.new
        end

        @auth = attrs[:auth] || NOMS::Command::Auth.new(:logger => @log,
                                                        :specified_identities =>
                                                        (attrs[:specified_identities] || []))
    end

    def clear_cache!
        @cacher.clear! unless @cacher.nil?
    end

    def auth
        @auth
    end

    def check_redirect(url)
        @redirect_checks.all? { |check| check.call(url) }
    end

    def origin=(new_origin)
        @origin = new_origin
    end

    def absolute_url(url)
        begin
            url = URI.parse url unless url.respond_to? :scheme
            url = URI.join(@origin, url) unless url.absolute?
            url
        rescue StandardError => e
            raise NOMS::Command::Error.new "Error parsing URL #{url} in context of #{@origin} (#{e.class}): #{e.message}"
        end
    end

    # Calculate a key for caching based on the method and URL
    def request_key(method, url, opt={})
        OpenSSL::Digest::SHA1.new([method, url.to_s].join(' ')).hexdigest
    end

    def request(method, url, data=nil, headers={}, tries=10, identity=nil, cached=nil)
        req_url = absolute_url(url)
        @log.debug "#{method} #{req_url}" + (headers.empty? ? '' : headers.inspect)

        # TODO: check Vary
        if @cache and cached.nil? and method.to_s.upcase == 'GET'
            key = request_key('GET', req_url)
            cached_response = NOMS::Command::UserAgent::Response.from_cache(@cacher.get(key), :logger => @log)
            if cached_response and cached_response.is_a? NOMS::Command::UserAgent::Response
                cached_response.logger = @log

                if cached_response.age < @max_age
                    if (cached_response.auth_hash.nil? or (identity and identity.auth_verify? cached_response.auth_hash))
                        if cached_response.current?
                            return [cached_response, req_url]
                        else
                            # Maybe we can revalidate it
                            if cached_response.etag
                                headers = { 'If-None-Match' => cached_response.etag }.merge headers
                                return self.request(method, url, data, headers, tries, identity, cached_response)
                            elsif cached_response.last_modified
                                headers = { 'If-Modified-Since' => cached_response.last_modified.httpdate }.merge headers
                                return self.request(method, url, data, headers, tries, identity, cached_response)
                            end
                        end
                    end
                end
            end
        end

        begin
            response = @client.request :method => method,
                                       :url => req_url,
                                       :body => data,
                                       :headers => headers
        rescue StandardError => e
            @log.debug e.backtrace.join("\n")
            raise NOMS::Command::Error.new "Couldn't retrieve #{req_url} (#{e.class}): #{e.message}"
        end
        @log.debug "-> #{response.statusText} (#{response.body.size} bytes of #{response.content_type})"
        @log.debug { JSON.pretty_generate(response.header) }

        case response.status
        when 401
            if identity
                # The identity we got was no good, try again
                identity.clear
                if tries > 0
                    identity = @auth.load(req_url, response)
                    # httpclient
                    @client.set_auth(identity['domain'], identity['username'], identity['password'])
                    return self.request(method, url, data, headers, tries - 1, identity)
                end
            else
                identity = @auth.load(req_url, response)
                # httpclient
                if identity
                    @client.set_auth(identity['domain'], identity['username'], identity['password'])
                    return self.request(method, url, data, headers, 2, identity)
                end
            end
            identity = nil
        when 304
            # The cached response has been revalidated
            if cached
                # TODO: Update Date: and Expires:/Cache-Control: headers
                # in cached response and re-cache, while maintaining
                # original_date
                key = request_key(method, req_url)
                @cacher.freshen key
                response, req_url = [cached, req_url]
            else
                raise NOMS::Command::Error.new "Server returned 304 Not Modified for #{new_url}, " +
                    "but we were not revalidating a cached copy"
            end
        when 302, 301
            new_url = response.header('Location')
            if check_redirect new_url
                raise NOMS::Command::Error.new "Can't follow redirect to #{new_url}: too many redirects" if tries <= 0
                return self.request(method, new_url, data, headers, tries - 1, identity)
            end
        end

        if identity and response.success?
            @log.debug "Login succeeded, saving #{identity['username']} @ #{identity}"
            identity.save :encrypt => (! @plaintext_identity)
        end

        if @cache and method.to_s.upcase == 'GET' and response.cacheable?
            cache_object = response.cacheable_copy
            cache_object.cached!
            if identity
                cache_object.auth_hash = identity.verification_hash
            end
            key = request_key(method, req_url)
            @cacher.set(key, cache_object.to_cache)
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
        @redirect_checks << block
    end

    def clear_redirect_checks
        @redirect_checks = [ ]
    end

    def pop_redirect_check
        unless @redirect_checks.empty?
            @redirect_checks.pop
        end
    end
end
