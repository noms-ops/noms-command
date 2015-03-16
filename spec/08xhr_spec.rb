#!/usr/bin/env rspec

require 'v8'
require 'fileutils'

require 'noms/command/xmlhttprequest'

describe NOMS::Command::XMLHttpRequest do

    before(:all) do
        # I'm going to go with this class variable for now
        NOMS::Command::XMLHttpRequest.origin = 'http://localhost:8787/'

        # Start the DNC application web server on port 8787
        FileUtils.rm_r 'test' if File.directory? 'test'
        system 'cp -R fixture test'
        system("sh -c '#{RbConfig.ruby} test/dnc.rb >test/dnc.out 2>&1 &'")
        sleep 2
    end

    after(:all) do
        Process.kill 'TERM', File.read('test/dnc.pid').to_i
        FileUtils.rm 'test/dnc.pid'
    end

    context 'from ruby' do

        before(:each) do
            @xhr = NOMS::Command::XMLHttpRequest.new
        end

        describe '#readyState' do
            it 'should be 0' do
                expect(@xhr.readyState).to eq 0
            end
        end

        describe 'statuses' do
            it 'should be equal to the correct number' do
                expect(@xhr.OPENED).to eq 1
                expect(@xhr.HEADERS_RECEIVED).to eq 2
                expect(@xhr.LOADING).to eq 3
                expect(@xhr.DONE).to eq 4
            end
        end

        describe '#open' do
            # open, send, check readyState and responseText

            it 'should retrieve web content' do
                @xhr.open('GET', 'http://localhost:8787/files/data.json', false)
                @xhr.send()
                expect(@xhr.responseText).to match /^\[/
            end

            it 'should raise an error on different-origin' do
                expect {
                    @xhr.open('GET', 'http://localhost:8786/files/data.json', false)
                }.to raise_error NOMS::Command::Error
            end

        end

        describe '#setRequestHeader' do

            it 'should set the request header' do
                @xhr.setRequestHeader('Accept', 'text/plain')
                expect(@xhr.headers['Accept']).to eq 'text/plain'
            end
        end

        describe '#onreadystatechange' do

        end

        describe '#abort' do

        end

    end

    context 'from javascript' do

        before(:each) do
            @v8 = V8::Context.new
            @v8[:XMLHttpRequest] = NOMS::Command::XMLHttpRequest
            @v8.eval 'var xhr = new XMLHttpRequest()'
        end

        describe '#open' do
            # open, send, check readyState and responseText
            it 'should retrieve web content' do
                @v8.eval 'xhr.open("GET", "http://localhost:8787/files/data.json", false)'
                @v8.eval 'xhr.send()'
                expect(@v8.eval 'xhr.readyState').to eq 4
                expect(@v8.eval 'xhr.responseText').to match(/^\[/)
            end
        end

        describe '#setRequestHeader' do

        end

        describe '#onreadystatechange' do

        end

        describe '#abort' do

        end

    end

end
