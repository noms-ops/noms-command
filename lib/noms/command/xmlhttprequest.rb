#!/usr/bin/env

class NOMS

end

class NOMS::Command

end

class NOMS::Command::XMLHttpRequest

    def initialize(window)
        @origin = window.origin
    end

end
