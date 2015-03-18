#!/usr/bin/env rspec

require 'spec_helper'

require 'uri'
require 'noms/command/application'
require 'noms/command/window'

describe NOMS::Command::Application do

    before(:all) do
        # Start the DNC application web server on port 8787
        setup_fixture
        start_server
    end

    after(:all) do
        stop_server
        teardown_fixture
    end

    describe '.new' do

        context 'with no arguments' do

            before(:each) do
                @app = NOMS::Command::Application.new(NOMS::Command::Window.new($0),
                                                   URI.parse('http://localhost:8787/dnc.json'),
                                                   [])
            end

        end

        it "should produce a usage message" do
            app = NOMS::Command::Application.new(NOMS::Command::Window.new($0),
                                                 'http://localhost:8787/dnc.json',
                                                 ['dnc'])
            app.fetch!
            app.render!
            expect(app.display).to include 'Usage:'
        end

        it "should produce a list of DNC records" do
            app = NOMS::Command::Application.new(NOMS::Command::Window.new($0),
                                                 'http://localhost:8787/dnc.json',
                                                 ['dnc', 'list'])
            app.fetch!
            app.render!
            expect(app.display.split("\n").length).to be > 9
        end

        it "should follow a redirect" do
            app = NOMS::Command::Application.new(NOMS::Command::Window.new($0),
                                                 'http://localhost:8787/alt/dnc.json',
                                                 ['dnc', 'list'])
            app.fetch!
            app.render!
            expect(app.display.split("\n").length).to be > 9
        end

    end

end

