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
            if item['$type']
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
        objlist['$labels'] ||= true
        objlist['$format'] ||= 'lines'
        raise NOMS::Command::Error.new("objectlist ('lines' format) must contain '$columns' list") unless
            objlist['$columns'] and objlist['$columns'].respond_to? :map

        case objlist['$format']
        when 'lines'
            render_object_lines objlist
        when 'yaml'
            filter_object_list(objlist).to_yaml
        when 'json'
            filter_object_list(objlist).to_json
        when 'csv'
            render_csv objlist
        else
            raise NOMS::Command::Error.new("objectlist format '#{objlist['$format']}' not supported")
        end
    end

    def filter_object_list(objlist)

        columns = objlist['$columns'].map do |spec|
            spec.respond_to?(:has_key?) ? spec['field'] : spec
        end

        objlist['$data'].map do |object|
            Hash[columns.map { |c| object[c] }]
        end
    end

    def normalize_columns(cols)
        cols.map do |spec|
            new_spec = { }
            if spec.respond_to? :has_key?
                new_spec.merge! spec
                raise NOMS::Command::Error.new("Column must contain 'field': #{spec.inspect}") unless
                    spec['field']
                new_spec['heading'] ||= new_spec['field']
            else
                new_spec = {
                    'field' => spec,
                    'heading' => spec
                }
            end
            new_spec
        end
    end

    def render_csv(objlist)
        labels = objlist.has_key?('$labels') ? objlist['$labels'] : true

        columns = normalize_columns(objlist['$columns'] || [])

        CSV.generate do |csv|
            csv << columns.map { |f| f['heading'] } if labels
            objlist['$data'].each do |object|
                csv << columns.map { |f| _string(object[f['field']]) }
            end
        end.chomp

    end


    def render_object_lines(objlist)
        columns = normalize_columns(objlist['$columns'] || [])
        labels = objlist.has_key?('$labels') ? objlist['$labels'] : true

        header_fmt = columns.map { |f| _fmth f }.join(' ')
        fmt = columns.map { |f| _fmt f }.join(' ')

        header_cells = columns.map { |f| f['heading'] }
        out = labels ? [ sprintf(header_fmt, *header_cells) ] : []

        out += objlist['$data'].map do |object|
            cells = columns.map { |f| _string(object[f['field']]) }
            sprintf(fmt, *cells)
        end

        out.join("\n")

    end

    def _string(datum)
        datum.kind_of?(Enumerable) ? datum.to_json : datum.to_s
    end

    def render_object(object)
        object['$format'] ||= 'record'

        case object['$format']
        when 'record'
            render_object_record object
        when 'json'
            JSON.pretty_generate(filter_object(object))
        when 'yaml'
            filter_object(object).to_yaml
        else
            raise NOMS::Command::Error.new("object format '#{object['$format']}' not supported")
        end
    end

    def render_object_record(object)
        labels = object.has_key?('$labels') ? object['$labels'] : true
        fields = (object['$fields'] || object['$data'].keys).sort
        data = object['$data']
        fields.map do |field|
            (labels ? (field + ': ') : '' ) + _string(data[field])
        end.join("\n")
    end

    def filter_object(object)
        if object['$fields']
            Hash[object['$fields'].map { |f| [f, object['$data'][f]] }]
        else
            object['$data']
        end
    end

end
