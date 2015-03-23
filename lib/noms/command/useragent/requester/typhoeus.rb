#!ruby

require 'noms/command/version'

require 'uri'
require 'typhoeus'

require 'noms/command/base'
require 'noms/command/useragent/requester'
require 'noms/command/useragent/response/typhoeus'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Requester < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Requester::Typhoeus < NOMS::Command::Base

    def initialize(opt={})
        @log = opt[:logger] || default_logger
        @log.debug "Creating #{self.class} with options: #{opt.inspect}"
        @agent_name = "noms/#{NOMS::Command::VERSION} typhoeus/#{::Typhoeus::VERSION}"
        @auth = { }
        @client_opts = {
            :ssl_verifypeer => false
        }
    end

    def get_auth(url)
        url = URI.parse(url) unless url.respond_to? :scheme
        domain = url.scheme + '://' + url.host + ':' + url.port.to_s + '/'
        @auth[domain] || { }
    end

    def request(opt={})
        url = opt[:url]
        spec = @client_opts.merge({
                                      :method => opt[:method] || opt[:get],
                                      :headers => {
                                          'User-Agent' => @agent_name
                                      }.merge(opt[:headers]),
                                      :body => opt[:body]
                                  }).merge(get_auth(url))
        request = ::Typhoeus::Request.new(opt[:url], spec)
        response = request.run
        NOMS::Command::UserAgent::Response::Typhoeus.new(response)
    end

    def set_auth(domain, username, password)
        @auth[domain] = { :userpwd => [username, password].join(':') }
    end

end
