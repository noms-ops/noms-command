#!/usr/bin/env rspec

require 'spec_helper'

require 'noms/command/application'

describe "NOMS::Command::Application" do

    before(:all) do
        setup_fixture 'test'
    end

    after(:all) do
        teardown_fixture 'test'
    end

    describe '.new' do
        context 'with local file' do
            before(:all) do
                @doc = NOMS::Command::Application.new(
                                                   "file:///#{Dir.pwd}/test/public/files/foo.json", [])
                @doc.fetch!
            end

            specify { expect(@doc.type).to eq 'noms-v2' }
            specify { expect(@doc.body).to have_key '$doctype' }
            specify { expect(@doc.body).to have_key '$body' }
            specify { expect(@doc.display).to eq 'Test output for foo.json' }
        end

        context 'with data URL' do
            before(:all) do
                @doc = NOMS::Command::Application.new(
                                                   'data:application/json,{"$doctype":"noms-v2","$body":[]}',
                                                   [])
                @doc.fetch!
            end

            specify { expect(@doc.type).to eq 'noms-v2' }
            specify { expect(@doc.body).to have_key '$doctype' }
            specify { expect(@doc.body).to have_key '$body' }
            specify { expect(@doc.display).to eq '' }
        end
    end

end

