#!ruby

require 'noms/command/version'

require 'httpclient'

require 'noms/command/base'
require 'noms/command/useragent/requester'
require 'noms/command/useragent/response/httpclient'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Requester < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Requester::HTTPClient < NOMS::Command::Base

    def initialize(opt={})
        @log = opt[:logger] || default_logger
        @log.debug "Creating #{self.class} with options: #{opt.inspect}"
        @client_opts = opt
        @client = ::HTTPClient.new :agent_name => "noms/#{NOMS::Command::VERSION} httpclient/#{::HTTPClient::VERSION}"
        @cookies = opt.has_key?(:cookies) ? opt[:cookies] : true
        if @cookies
            cookie_jar = File.join(NOMS::Command.home, 'cookies.txt')
            @client.set_cookie_store(cookie_jar)
        else
            @client.cookie_manager = nil
        end
        @client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    def request(opt={})
        response = @client.request(opt[:method].to_s.upcase, opt[:url], '', opt[:body], opt[:headers])
        noms_response = NOMS::Command::UserAgent::Response::HTTPClient.new(response)
        if @cookies
            # @client.save_cookie_store - There is a bug where
            # it thinks @is_saved is satisfied all the time and
            # the file isn't written, which is why we call
            # cookie manager directly.
            @client.cookie_manager.save_all_cookies(true)
        end
        noms_response
    end

    def set_auth(domain, username, password)
        @client.set_auth(domain, username, password)
    end

end
