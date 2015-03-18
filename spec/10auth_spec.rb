#!/usr/bin/env rspec

require 'spec_helper'

describe "NOMS::Command::Application" do

    before(:all) do
        setup_fixture
        start_server
    end

    after(:all) do
        stop_server
        teardown_fixture
    end

    describe ".new" do

        before(:each) do
            @app = NOMS::Command::Application.
                new(NOMS::Command::Window.new($0),
                    'http://localhost:8787/auth/dnc.json',
                    ['dnc'])
        end


        # it "prompts for authentication" do
        #     expect {
        #         @app.fetch!
        #     }.to output(Regexp.new 'Authorization Required at http://localhost:8787').to_stdout
        # end

    end

end
