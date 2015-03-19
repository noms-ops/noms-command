#!ruby

require 'noms/command/version'

require 'highline/import'

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

    def prompt(prompt_text, echo=true)
        echo = true if echo.nil?
        @log.debug "prompt(#{prompt_text.inspect}, #{echo.inspect})"
        v = ask(prompt_text) { |p| p.echo = false unless echo }
        @log.debug "-> #{v}"
        v
    end

end

class NOMS::Command::Window::Console < NOMS::Command::Base

    def initialize(logger=nil)
        @log = logger || default_logger
    end

    # Some implementations have a kind of format string. I don't
    def log(*items)
        @log.debug(items.map { |s| _string(s) }.join(', '))
    end

    def _string(s)
        s = _sanitize(s)
        s.kind_of?(Enumerable) ? s.to_json : s.inspect
    end

    # Get rid of V8 stuff
    def _sanitize(thing)
        # This really needs to go into a class
        if thing.kind_of? V8::Array or thing.respond_to? :to_ary
            thing.map do |item|
                _sanitize item
            end
        elsif thing.respond_to? :keys
            Hash[
                 thing.keys.map do |key|
                     [key, _sanitize(thing[key])]
                 end]
        else
            thing
        end
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
