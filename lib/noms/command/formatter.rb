#!ruby

require 'json'
require 'yaml'
require 'csv'

class NOMS

end

class NOMS::Command

end

class NOMS::Command::Formatter

    def initialize(data=nil, opt={})
        @data = data
        @format_raw_object = opt[:format_raw_object] || lambda { |o| o.to_yaml }
    end

    def render(item=@data)
        if item.nil?
            ''
        elsif item.respond_to? :to_ary
            item.map { |it| render it }.join("\n")
        elsif item.respond_to? :has_key?
            if item.has_key? '$type'
                case item['$type']
                when 'object-list'
                    render_object_list item
                when 'object'
                    render_object item
                end
            else
                # It's a raw object, do YAML
                @format_raw_object.call item
            end
        else
            item.to_s
        end
    end

    def render_object_list(objlist)

    end

    def render_object(obj)

    end

end
