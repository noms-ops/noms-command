#!rspec

require 'noms/command/formatter'
require 'yaml'

describe NOMS::Command::Formatter do

    describe '#render' do

        subject(:formatter) { NOMS::Command::Formatter.new }

        it 'renders nil as ""' do
            expect(formatter.render(nil)).to eq ''
        end

        it 'renders a string as a string' do
            expect(formatter.render("one")).to eq 'one'
        end

        it 'renders a number as a string' do
            expect(formatter.render(1)).to eq '1'
        end

        it 'renders a boolean as a string' do
            expect(formatter.render(true)).to eq 'true'
        end

        it 'renders an array of strings as a list of lines' do
            lines = [
                'one',
                'two',
                'three' ]
            expect(formatter.render(lines)).to eq "one\ntwo\nthree"
        end

        it 'renders a raw object as a YAML object' do
            object = {
                'one' => 1,
                'two' => 2,
                'three' => 3
            }
            expect(formatter.render(object)).to eq object.to_yaml
        end

    end

end
