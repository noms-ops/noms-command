require 'sinatra/base'
require 'json'

# Implement Do Not Call List Example REST application
# and static file server
class DNC < Sinatra::Application

    set :port, 8787
    set :root, File.expand_path("#{File.dirname(__FILE__)}")
    enable :static

    File.open(File.join(settings.root, 'dnc.pid'), 'w') {|f| f.puts Process.pid }

    def load_data
        JSON.load(File.open(File.join(settings.root, 'public', 'files', 'data.json')))
    end

    def write_data(data)
        File.open(File.join(settings.root, 'public', 'files', 'data.json'), 'w') { |fh| fh << data.to_json }
    end

    get '/dnc' do
        data = load_data
        [ 200, { 'Content-type' => 'application/json'},
            JSON.pretty_generate(data) ]
    end

    get '/dnc/:id' do
        data = load_data
        object = data.find { |e| e['id'] == params[:id].to_i }
        if object
            [ 200, { 'Content-type' => 'application/json' },
                JSON.pretty_generate(object) ]
        else
            404
        end
    end

    post '/dnc' do
        request.body.rewind
        new_object = JSON.parse request.body.read

        data = load_data
        # How unsafe is this?
        new_object['id'] = data.map { |e| e['id'] }.max + 1
        data << new_object
        write_data data

        [ 201, { 'Content-type' => 'application/json' },
            JSON.pretty_generate(new_object) ]
    end

    put '/dnc/:id' do
        request.body.rewind
        new_object = JSON.parse request.body.read

        data = load_data
        new_data = data.reject { |e| e['id'] == params[:id].to_i }
        if new_data.size == data.size
            404
        else
            new_object['id'] = params[:id].to_i
            new_data << new_object
            write_data new_data

            [ 200, { 'Content-type' => 'application/json' },
                JSON.pretty_generate(new_object) ]
        end
    end

    delete '/dnc/:id' do
        data = load_data
        new_data = data.reject { |e| e['id'] == params[:id].to_i }

        if new_data.size == data.size
            404
        else
            write_data new_data
            204
        end
    end

    run! if app_file = $0

end
