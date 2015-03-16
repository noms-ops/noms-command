#!ruby

require 'fileutils'

require 'noms/command/application'

describe "NOMS::Command::Application" do

    before(:all) do
        FileUtils.rm_r 'test' if File.directory? 'test'
        system('cp -R fixture test')
    end

    after(:all) do
        FileUtils.rm_r 'test' if File.directory? 'test'
    end

    describe '.new' do
        context 'with local file' do
            before(:all) do
                @doc = NOMS::Command::Application.new(NOMS::Command::Window.new($0),
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
                @doc = NOMS::Command::Application.new(NOMS::Command::Window.new($0),
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

