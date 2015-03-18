#!/usr/bin/env rspec

require 'spec_helper'

require 'v8'
require 'json'

require 'noms/command/xmlhttprequest'

describe NOMS::Command::XMLHttpRequest do

    before(:all) do
        # I'm going to go with this class variable for now

        # Start the DNC application web server on port 8787
        setup_fixture 'test'
        start_server 'test'
    end

    after(:all) do
        stop_server 'test'
        teardown_fixture 'test'
    end

    before(:each) do
        NOMS::Command::XMLHttpRequest.origin = 'http://localhost:8787/files/dnc.json'
        NOMS::Command::XMLHttpRequest.useragent = nil
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

            it 'should retrieve web content from relative URL' do
                @xhr.open('GET', '/files/data.json', false)
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

        describe '#abort' do

        end

    end

    context 'from javascript' do

        before(:each) do
            @v8 = V8::Context.new
            @v8[:XMLHttpRequest] = NOMS::Command::XMLHttpRequest
            @v8.eval 'var xhr = new XMLHttpRequest()'
            @xhr = @v8[:xhr]
        end

        describe '#open' do
            # open, send, check readyState and responseText
            it 'should retrieve web content' do
                @v8.eval 'xhr.open("GET", "http://localhost:8787/files/data.json", false)'
                @v8.eval 'xhr.send()'
                expect(@v8.eval 'xhr.responseText').to match(/^\[/)
                expect(@v8.eval 'xhr.readyState').to eq 4
            end

            it 'should retrieve web content from relative URL' do
                @v8.eval 'xhr.open("GET", "/files/data.json", false)'
                @v8.eval 'xhr.send()'
                expect(@v8.eval 'xhr.responseText').to match(/^\[/)
                expect(@v8.eval 'xhr.readyState').to eq 4
            end

            it 'should post objects to rest app' do
                @v8[:newdata] = {
                    'name' => 'Frances Simmons',
                    'street' => '180 Tomkins Blcd',
                    'city' => 'Minneapolis, MN  55401',
                    'phone' => '(612) 555-0180'
                }.to_json
                @v8.eval 'xhr.open("POST", "/dnc", false);'
                @v8.eval 'xhr.send(newdata);'
                obj = JSON.parse(@v8.eval 'xhr.responseText')
                expect(obj).to have_key 'id'

                @v8.eval "xhr.open(\"GET\", \"/dnc/#{obj['id']}\", false);"
                @v8.eval 'xhr.send();'
                retobj = JSON.parse(@v8.eval 'xhr.responseText')
                expect(retobj['name']).to eq 'Frances Simmons'
            end

            it 'should update objects in rest app' do
                @v8.eval 'xhr.open("GET", "/dnc/1", false);'
                @v8.eval 'xhr.send();'
                obj = JSON.parse(@v8.eval 'xhr.responseText')
                obj['phone'] = '(999) 555-9999'
                @v8[:newobject] = obj.to_json

                @v8.eval 'xhr.open("PUT", "/dnc/1", false);'
                @v8.eval 'xhr.send(newobject);'
                newobject = JSON.parse(@v8.eval 'xhr.responseText')
                expect(newobject['id']).to eq 1
                expect(newobject['phone']).to eq '(999) 555-9999'

                @v8.eval 'xhr.open("GET", "/dnc/1", false);'
                @v8.eval 'xhr.send();'
                retobj = JSON.parse(@v8.eval 'xhr.responseText')
                expect(retobj['phone']).to eq '(999) 555-9999'
            end

            it 'should delete objects in rest app' do
                @v8.eval 'xhr.open("DELETE", "/dnc/2", false);'
                @v8.eval 'xhr.send();'
                expect(@v8.eval 'xhr.status').to eq 204

                @v8.eval 'xhr.open("GET", "/dnc/2", false);'
                @v8.eval 'xhr.send();'
                expect(@v8.eval 'xhr.status').to eq 404
            end

            it 'should not follow cross-origin redirects' do
                @v8.eval 'xhr.open("GET", "/readme", false);'
                @v8.eval 'xhr.send();'
                expect(@v8.eval 'xhr.status').to eq 302
                expect(@v8.eval 'xhr.responseText').to eq 'README'
            end

        end

        describe '#setRequestHeader' do

        end

        describe '#onreadystatechange' do

            it 'should be triggered by state change events' do
                @v8.eval <<-JS
                    var content = "";
                    xhr.onreadystatechange = function() {
                        if (this.readyState == this.DONE) {
                             content = this.responseText;
                        }
                    }
                JS
                @v8.eval 'xhr.open("GET", "/files/data.json", true)'
                @v8.eval 'xhr.send()'
                @xhr.useragent.wait
                expect(@v8[:content]).to match(/^\[/)
            end

        end

        describe '#abort' do

            it 'cancels a request' do
                # We don't really have true asynchronous requests,
                # in particular we can't interrupt between calling
                # send() and the readyState changing to 4. So
                # this is kind of a no-op.

                @v8.eval 'xhr.open("GET", "/files/data.json", true);'
                @v8.eval 'xhr.abort();'
                expect(@v8.eval 'xhr.readyState').to eq 0
            end

        end

    end

end
