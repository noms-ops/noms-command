#!ruby

require 'json'
require 'yaml'
require 'csv'

require 'noms/command/error'

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

    def _fmt(spec)
        '%' +
            ((spec['align'] && spec['align'] == 'right') ? '' : '-') +
            (spec['width'] ? spec['width'].to_s : '') +
            (spec['maxwidth'] ? '.' + spec['maxwidth'] : '') +
            's'
    end

    def _fmth(spec)
        # Headers are always left-aligned
        '%-' +
            (spec['width'] ? spec['width'].to_s : '') +
            (spec['maxwidth'] ? '.' + spec['maxwidth'] : '') +
            's'
    end

    def render_object_list(objlist)
        objlist['$header'] ||= true
        objlist['$format'] ||= 'lines'
        raise NOMS::Command::Error.new("objectlist ('lines' format) must contain '$columns' list") unless
            objlist['$columns'] and objlist['$columns'].respond_to? :map

        case objlist['$format']
        when 'lines'
            render_object_lines objlist
        else
            raise NOMS::Command::Error.new("objectlist format '#{objlist['$format']}' not supported")
        end
    end

    def render_object_lines(objlist)

        columns = objlist['$columns'].map do |spec|
            new_spec = { }
            if spec.respond_to? :has_key?
                new_spec.merge! spec
                raise NOMS::Command::Error.new("Column must contain 'field': #{spec.inspect}") unless
                    spec.has_key? 'field'
                new_spec['heading'] ||= new_spec['field']
            else
                new_spec = {
                    'field' => spec,
                    'heading' => spec
                }
            end
            new_spec
        end

        header_fmt = columns.map { |f| _fmth f }.join(' ')
        fmt = columns.map { |f| _fmt f }.join(' ')

        header_cells = columns.map { |f| f['heading'] }
        out = objlist['$header'] ? [ sprintf(header_fmt, *header_cells) ] : []

        out += objlist['$data'].map do |object|
            cells = columns.map { |f| object[f['field']] }
            sprintf(fmt, *cells)
        end

        out.join("\n")

    end

    def render_object(obj)

    end

end
