#!/usr/bin/env rspec

require 'spec_helper'

require 'json'
require 'base64'
require 'logger'

require 'noms/command/application'

def make_script_app(js, opt={})
    doc = {
        '$doctype' => 'noms-v2',
        '$body' => ['Usage:','   noms echo <string>'],
        '$script' => [js]
    }
    NOMS::Command::Application.new('data:application/json,' + JSON.pretty_generate(doc),
                                   %w(echo one two three), opt)
end

describe NOMS::Command::Application do

    describe '.render!' do

        subject(:doc) do
            make_script_app "window.document.body = window.document.argv.slice(1).join(' ')"
        end

        it "should have initial output" do
            doc.fetch!
            expect(doc.display).to eq "Usage:\n   noms echo <string>"
        end

        it "should render by echoing arguments" do
            doc.fetch!
            doc.render!
            expect(doc.display).to eq "one two three"
        end

    end

    context 'in javascript runtime' do

        describe ' window' do

            describe '.name' do

                it "should have a name" do
                    app = make_script_app "document.body = window.name"
                    app.window.name = 'test-js_spec'
                    app.fetch!
                    app.render!
                    expect(app.display).to eq 'test-js_spec'
                end

            end

        end

        describe 'console' do

            it "should produce debugging output" do
                logcatcher = StringIO.new
                log = Logger.new(logcatcher)
                log.level = Logger::DEBUG

                app = make_script_app("console.log('test debug output')", :logger => log)
                app.fetch!
                app.render!
                expect(logcatcher.string).to match(/^D,.*test debug output/)
            end

        end

        describe 'location' do

            it "should describe URL location" do
                app = make_script_app "document.body = location.protocol"
                app.fetch!
                app.render!
                expect(app.display).to eq 'data'
            end

        end

    end
end
