require 'sinatra/base'
require 'json'

# Implement Do Not Call List Example REST application
# and static file server
class DNC < Sinatra::Application

    set :port, 8787
    set :root, File.expand_path("#{File.dirname(__FILE__)}")
    enable :static
    set :public_folder, Proc.new { File.join(root, 'files') }

    File.open(File.join(root, 'dnc.pid'), 'w') {|f| f.puts Process.pid }

    def load_data
        JSON.load(File.open(File.join(settings.root, 'files', 'data.json')))
    end

    def write_data
        File.open(File.join(settings.root, 'files', 'data.json'), 'w') { |fh| fh << data.to_json }
    end

    get '/dnc' do
        data = load_data
        status 200
        content_type 'application/json'
        body JSON.pretty_generate(data)
    end

    get '/dnc/:id' do
        data = load_data
        object = data.find { |e| e['id'] == params[:id].to_i }
        if object
            status 200
            content_type 'application/json'
            body JSON.pretty_generate(object)
        else
            status 404
        end
    end

    post '/dnc' do
        request.body.rewind
        new_object = JSON.parse request.body.read

        data = load_data
        # How unsafe is this?
        data << new_object.merge({ 'id' => data.map { |e| e['id'] }.max + 1 })
        status 201
        content_type 'application/json'
        body JSON.pretty_generate(new_object)
    end

    put '/dnc/:id' do
        request.body.rewind
        new_object = JSON.parse request.body.read

        data = load_data
        new_data = data.reject { |e| e['id'] == params[:id].to_i }
        if new_data.size == data.size
            status 404
        else
            new_object['id'] = params[:id].to_i
            new_data << new_object
            write_data new_data
            status 200
            content_type 'application/json'
            body JSON.pretty_generate(new_object)
        end
    end

    delete '/dnc/:id' do
        data = JSON.load
        new_data = data.reject { |e| e['id'] == params[:id].to_i }
        if new_data.size == data.size
            status 404
        else
            status 204
            write_data new_data
        end
    end

    run! if app_file = $0

end
