#!/usr/bin/env ruby

require 'noms/command/version'

require 'typhoeus'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::UserAgent < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response < NOMS::Command::Base

end

class NOMS::Command::UserAgent::Response::Typhoeus < NOMS::Command::UserAgent::Response

    def initialize(httpresponse, opts={})
        super
        if @response.return_code != :ok
            raise NOMS::Command::Error.new "Client error[#{@response.return_code.inspect}]: #{@response.return_message}"
        end
        content_encoding = self.content_encoding || 'utf-8'
        @body = @response.body

        if @body

            begin
                @log.debug "Forcing body string encoding to #{content_encoding}"
                @body.force_encoding(content_encoding)
            rescue Encoding::UndefinedConversionError
                @log.debug "   (coercing 'binary' to '#{content_encoding}')"
                @body = @body.encode('utf8', 'binary', :undef => :replace, :invalid => :replace)
            end

        end
    end

    def body
        @body || @response.body
    end

    def success?
        @response.success?
    end

    def header(hdr=nil)
        if hdr.nil?
            @response.headers
        else
            Hash[@response.headers.map { |h, v| [h.downcase, v] }][hdr.downcase]
        end
    end

    def status
        @response.code.to_i
    end

    def statusText
        @response.code.to_s + ' ' + @response.status_message
    end

    def content_type
        @response.headers['Content-Type']
    end

end
