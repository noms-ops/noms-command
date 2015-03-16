#!ruby

require 'base64'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::URInion

end

class NOMS::Command::URInion::Data

    attr_accessor :scheme, :host, :port, :fragment, :query, :data, :path,
        :data_encoding, :mime_type, :user, :password, :raw_data,
        :character_set

    def self.parse(urltext)
        self.new(urltext)
    end

    def initialize(urltext)
        @host = nil
        @port = nil
        @fragment = nil
        @user = nil
        @path = nil
        @password = nil
        @character_set = nil

        @scheme, rest = urltext.split(':', 2)
        raise NOMS::Command::Error.new "URL is not data: (scheme = #{@scheme})" unless @scheme == 'data'
        meta, @raw_data = rest.split(',', 2)
        fields = meta.split(';')
        if fields[-1] == 'base64'
            @data_encoding = fields.pop
        end

        unless fields[0].nil? or fields[0].empty?
            @mime_type = fields.shift
        end

        fields.each do |field|
            if m = /charset=(.*)/.match(field)
                @character_set = m[1]
            end
        end

        case @data_encoding
        when 'base64'
            @data = Base64.urlsafe_decode64
        else
            @data = @raw_data
        end

    end

end
