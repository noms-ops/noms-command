#!/usr/bin/env rspec

require 'spec_helper'

require 'noms/command/useragent'

describe NOMS::Command::UserAgent do

    describe '.get' do

        before(:each) do
            @input = StringIO.new
            @input.truncate(@input.rewind)
            @output = StringIO.new
            @output.truncate(@output.rewind)
            @auth = NOMS::Command::Auth.new :prompt_input => @input, :prompt_output => @output, :force_prompt => true
        end

        it "does basic authentication with user input" do
            ua = NOMS::Command::UserAgent.new 'http://localhost:8787/', :auth => @auth
            @input << "testuser\ntestpass\n"
                @input.rewind
            response, = ua.get 'http://localhost:8787/auth/ok'
            expect(response.success?).to be_truthy
        end

        it "prompts three times for authentication" do

        end

        it "saves authentication identity for subsequent uses" do

        end

        it "does basic authentication with identity file" do

        end

        it "saves a plaintext identity in specified file" do

        end

        it "doesn't save an identity for a specified identity" do

        end

    end

end
