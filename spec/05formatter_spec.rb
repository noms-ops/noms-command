#!/usr/bin/env rspec

require 'spec_helper'

require 'yaml'

require 'noms/command/formatter'

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

        it 'renders a object-list as formatted lines' do
            object_list = {
                '$type' => 'object-list',
                '$header' => true,
                '$columns' => [
                    {
                        'field' => 'priority',
                        'width' => 3,
                        'align' => 'right',
                        'heading' => 'Pri'
                    },
                    {
                        'field' => 'title',
                        'width' => 10,
                        'heading' => 'Name'
                    },
                    'description'
                ],
                '$data' => [
                    {
                        'title' => 'Issue 1',
                        'priority' => 3,
                        'description' => 'The first issue'
                    },
                    {
                        'title' => 'Issue 2',
                        'priority' => 2,
                        'description' => 'The second issue'
                    }
                ]
            }
            output = <<-TEST.gsub(/^\s{12}/,'').gsub(/\n$/,'')
            Pri Name       description
              3 Issue 1    The first issue
              2 Issue 2    The second issue
            TEST
            expect(formatter.render(object_list)).to eq output
        end

    end

end
