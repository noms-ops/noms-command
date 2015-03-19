#!ruby

require 'noms/command/version'

require 'noms/command/base'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Window < NOMS::Command::Base

    attr_accessor :document, :name, :origin
    attr_reader :console, :origin, :location

    def initialize(invoker=$0, origin=nil, opt={})
        @document = nil
        @origin = origin
        @name = invoker
        @log = opt[:logger] || default_logger
        @console = NOMS::Command::Window::Console.new(@log)
        @location = NOMS::Command::Window::Location.new(self)
    end

    def isatty()
        $stdout.tty?
    end

    def alert(msg)
        @log.error msg
    end

end

class NOMS::Command::Window::Console < NOMS::Command::Base

    def initialize(logger=nil)
        @log = logger || default_logger
    end

    # Some implementations have a kind of format string. I don't
    def log(*items)
        @log.debug(items.map { |s| _sanitize(s) }.join(', '))
    end

    def _sanitize(s)
        s.respond_to?(:to_str) ? s : s.to_json
    end

end

class NOMS::Command::Window::Location

    {   :protocol => :scheme,
        :origin => :to_s,
        :pathname => :path,
        :href => :to_s,
        :hostname => :host,
        :hash => :fragment,
        :search => :query,
        :port => :port
    }.each do |loc_attr, uri_attr|
        define_method(loc_attr) do
            self.field uri_attr
        end
    end

    def initialize(window)
        @window = window
        # Setup simple equivalences
    end

    def field(name)
        @window.origin.send(name) if @window.origin.respond_to? name
    end

    def host
        [self.hostname, self.port].join(':')
    end

end
