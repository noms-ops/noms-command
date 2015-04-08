#!/usr/bin/env rspec

require 'spec_helper'

require 'noms/command/useragent'

describe NOMS::Command::UserAgent do

    describe '.get' do

        before(:all) do
            setup_fixture
            start_server
        end

        after(:all) do
            stop_server
            teardown_fixture
        end

        before(:each) do
            @input = StringIO.new
            @input.truncate(@input.rewind)
            @output = StringIO.new
            @output.truncate(@output.rewind)
            @auth = NOMS::Command::Auth.new :prompt_input => @input, :prompt_output => @output, :force_prompt => true
            Dir[NOMS::Command::Auth::Identity.identity_dir + '/*'].each { |f| File.unlink f }
            File.unlink NOMS::Command::Auth::Identity.vault_keyfile if File.exist? NOMS::Command::Auth::Identity.vault_keyfile
            @ua = NOMS::Command::UserAgent.new 'http://localhost:8787/', :auth => @auth
        end

        it "does basic authentication with user input" do
            @input << "testuser\ntestpass\n"
            @input.rewind
            response, = @ua.get 'http://localhost:8787/auth/ok'
            expect(response.success?).to be_truthy
            expect(@output.string).to include %q(http://localhost:8787/ (Authorization Required) username:)
        end

        it "prompts three times for authentication" do
            @input << "testuser\nfailure\ntestuser\nfailure\ntestuser\ntestpass\n"
            @input.rewind
            response, = @ua.get 'http://localhost:8787/auth/ok'
            pat = %r{http://localhost:8787/ \(Authorization Required\) username:.*?$}
            expect(@output.string.scan(pat).size).to eq 3
            expect(response.success?).to be_truthy
        end

        it "saves authentication identity for subsequent uses" do
            @input << "testuser\ntestpass\n"
            @input.rewind
            response0, = @ua.get 'http://localhost:8787/auth/ok'
            expect(response0.success?).to be_truthy

            @input.truncate(@input.rewind)

            response1, = @ua.get 'http://localhost:8787/auth/ok'
            expect(response1.success?).to be_truthy
        end

        it "does basic authentication with identity file" do
            auth = NOMS::Command::Auth.new :specified_identities => ['test/identity']
            ua = NOMS::Command::UserAgent.new 'http://localhost:8787', :auth => auth
            response, = ua.get 'http://localhost:8787/auth/ok'
            expect(response.success?).to be_truthy
        end

        it "saves a plaintext identity in specified file" do
            ua = NOMS::Command::UserAgent.new 'http://localhost:8787/', :auth => @auth,
                :plaintext_identity => 'test/testuser.id'
            @input << "testuser\ntestpass\n"
            @input.rewind
            response, = ua.get 'http://localhost:8787/auth/ok'
            expect(response.success?).to be_truthy
            expect(File.exist? 'test/testuser.id').to be_truthy
            expect(File.read('test/testuser.id')).to include %q{Authorization+Required=http://localhost:8787/}
        end

        it "doesn't save an identity for a specified identity" do
            auth = NOMS::Command::Auth.new :prompt_input => @input, :prompt_output => @output,
                :force_prompt => true, :specified_identities => ['test/identity']
            ua = NOMS::Command::UserAgent.new 'http://localhost:8787', :auth => auth
            response0, = ua.get 'http://localhost:8787/auth/ok'
            expect(response0.success?).to be_truthy
            expect(File.exist? NOMS::Command::Auth::Identity.vault_keyfile).to be_falsey
        end

    end

end
