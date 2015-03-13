require 'sinatra'

# Implement Do Not Call List Example REST application
# and static file server
class DNC < Sinatra::Application
    File.open('dnc.pid', 'w') {|f| f.puts Process.pid }

    set :root, File.expand_path("#{File.dirname(__FILE__)}")
    enable :static
    set :public_folder, 'dnc'

    get '/dnc' do
        data = JSON.load(File.open('dnc/data.json'))
        status 200
        content_type 'application/json'
        body data
    end

    get '/dnc/:id' do
        data = JSON.load(File.open('dnc/data.json'))
        content_type 'application/json'
        object = data.find { |e| e['id'] == params[:id] }
        if object
            status 404
        else
            status 200
            body object
        end
    end

    post '/dnc' do
        request.body.rewind
        new_object = JSON.parse request.body.read

        data = JSON.load(File.open('dnc/data.json'))
        # How unsafe is this?
        data << new_object.merge({ 'id' => data.map { |e| e['id'] }.max + 1 })
        File.open('dnc/data.json', 'w') { |fh| fh << data.to_json }
        status 201
        content_type 'application/json'
        body JSON.pretty_generate(new_object)
    end

    put '/dnc/:id' do
        request.body.rewind
        new_object = JSON.parse request.body.read

        data = JSON.load(File.open('dnc/data.json'))
        new_data = data.reject { |e| e['id'] == params['id'] }
        if new_data.size == data.size
            status 404
        else
            new_object['id'] = params['id']
            data << new_object
            File.open('dnc/data.json', 'w') { |fh| fh << data.to_json }
            status 200
            content_type 'application/json'
            body JSON.pretty_generate(new_object)
        end
    end

    delete '/dnc/:id' do
        data = JSON.load
        new_data = data.reject { |e| e['id'] == params['id'] }
        if new_data.size == data.size
            status 404
        else
            status 204
        end
    end

end
