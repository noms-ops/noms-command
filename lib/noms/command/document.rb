#!ruby

require 'noms/command/error'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Document

    def initialize(doc)
        raise NOMS::Command::Error.new "Document type '#{docobj['$doctype']}' not understood" unless
            doc['$doctype'] == 'noms-v2'
        @doc = doc
    end

    # Make these synonymous with the keys
    def body
        @doc['$body']
    end

    def body=(rval)
        @doc['$body'] = rval
    end

    def script
        @doc['$script']
    end

    def script=(rval)
        @doc['$script'] = rval
    end

    def argv
        @doc['$argv']
    end

    def argv=(rval)
        @doc['$argv'] = rval
    end

    def exitcode
        @doc['$exitcode']
    end

    def exitcode=(rval)
        unless rval.respond_to?(:to_int) and rval <= 255 and rval >= 0
            raise NOMS::Command::Error.new "Exitcode ${rval.inspect} out of range"
        end
        @doc['$exitcode'] = rval
    end

end
