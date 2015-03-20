#!/usr/bin/env rspec

require 'spec_helper'

require 'digest/sha1'

require 'noms/command/application'
require 'noms/command/auth'

describe NOMS::Command::Auth::Identity do

    before(:all) do
        setup_fixture
        NOMS::Command::Auth::Identity.identity_dir = 'test/identities'
        FileUtils.rm_r 'test/identities' if File.directory? 'test/identities'
        File.unlink 'test/identities/.noms-vault-key' if File.exist? 'test/identities/.noms-vault-key'
    end

    after(:all) do
        teardown_fixture
    end

    before(:each) do
        @identity = NOMS::Command::Auth::Identity.new({ 'id' => 'Authorization+Required=http://localhost:8787/',
                                                          'data' => 'testdata' })
        identity_file = File.join(NOMS::Command::Auth::Identity.identity_dir, @identity.id_number)
        @vault_keyfile = File.join(NOMS::Command::Auth::Identity.identity_dir, '.noms-vault-key')
        File.unlink "#{identity_file}.json" if File.exist? "#{identity_file}.json"
        File.unlink "#{identity_file}.enc" if File.exist? "#{identity_file}.json"
        File.unlink @vault_keyfile if File.exist? @vault_keyfile
    end

    describe '.new' do

        it "should create an identity" do
            identity = NOMS::Command::Auth::Identity.new({'id' => 'Authorization+Required=http://localhost:8787/',
                                                             'data' => 'testdata' })
            expect(identity).to be_a NOMS::Command::Auth::Identity
        end

    end

    describe "#id_number" do

        it "should return the hash of the identity id" do
            comp_id = Digest::SHA1.new.update(@identity['id']).hexdigest
            expect(@identity.id_number).to eq comp_id
        end

    end

    describe "#save" do

        it "should save the identity in an encrypted file" do
            file = @identity.save
            expect(File.basename(file)).to eq @identity.id_number + '.enc'
            expect(File.exist? file).to be_truthy
            expect(File.read file).to_not match(/Authorization/)
            expect(File.exist? File.join(NOMS::Command::Auth::Identity.identity_dir, '.noms-vault-key')).to be_truthy
        end

        it "should save unencrypted when directed" do
            file = @identity.save :encrypt => false
            expect(File.basename(file)).to eq @identity.id_number + '.json'
            expect(File.read file).to match(/Authorization/)
        end

        it "should save in specific file when asked" do
            file = @identity.save :file => 'test/identities/test-identity.json', :encrypt => false
            expect(File.basename(file)).to eq 'test-identity.json'
            expect(File.read file).to match(/Authorization/)
        end

    end

    describe '.saved' do

        it 'should be false when not saved' do
            expect(NOMS::Command::Auth::Identity.saved @identity['id']).to be_falsey
        end

        it 'should be true when saved' do
            file = @identity.save
            expect(NOMS::Command::Auth::Identity.saved @identity['id']).to be_truthy
        end

        it 'should be false when not decryptable' do
            file = @identity.save
            expect(NOMS::Command::Auth::Identity.saved @identity['id']).to be_truthy

            File.unlink NOMS::Command::Auth::Identity.vault_keyfile
            expect(NOMS::Command::Auth::Identity.saved @identity['id']).to be_falsey
        end

        it 'should be false when too old' do
            file = @identity.save
            expect(NOMS::Command::Auth::Identity.saved @identity['id']).to be_truthy
            old_hash = Digest::SHA1.new.update(File.read @vault_keyfile).hexdigest

            old_ts = Time.now - 24 * 3600
            File.utime(old_ts, old_ts, @vault_keyfile)
            expect(NOMS::Command::Auth::Identity.saved @identity['id']).to be_falsey
            new_hash = Digest::SHA1.new.update(File.read @vault_keyfile).hexdigest
            expect(new_hash).to_not eq old_hash
        end

        it 'should load an identity' do
            file = @identity.save

            id_data = NOMS::Command::Auth::Identity.saved @identity['id']
            expect(id_data['id']).to eq @identity['id']
        end

        it 'should update vault key mtime' do
            file = @identity.save

            old_ts = Time.now - (5 * 60)
            File.utime(old_ts, old_ts, @vault_keyfile)

            id_data = NOMS::Command::Auth::Identity.saved @identity['id']
            new_identity = NOMS::Command::Auth::Identity.new(id_data)
            new_ts = File.stat(@vault_keyfile).mtime
            expect(Time.now - new_ts).to be < 5
        end

    end

end

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
                new('http://localhost:8787/auth/dnc.json', ['dnc'])
        end


        # it "prompts for authentication" do
        #     expect {
        #         @app.fetch!
        #     }.to output(Regexp.new 'Authorization Required at http://localhost:8787').to_stdout
        # end

    end

end
