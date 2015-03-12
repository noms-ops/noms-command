#!/usr/bin/env rspec

require 'noms/command'

describe NOMS::Command do
    describe '.run' do
        context 'with no arguments' do
            it 'prints a usage message' do
                expect { NOMS::Command.run([]) }.to output(/Usage:/).to_stdout
            end
        end
    end
end
