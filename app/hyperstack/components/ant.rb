# Wrap the Ant Library
# Most of the Ant Components can be used as is.
# However Ant::Table needs some massaging of the data
# To make it easier to use.
class Ant < Hyperstack::Component::NativeLibrary
  imports 'Ant'
  rename Table: :NativeTable

  # Wrapper for Ant Table component so it works with AR records
  class Table < HyperComponent
    param :records          # any collection of ActiveRecord like objects
    param :columns          # array of column descriptions (see below for details)
    param accordion: false # true if only one row can be expanded at a time

    # [
    #   # columns can can simply be the name of the attribute.  The column header
    #   # will be the humanized attribute name (i.e. Name)
    #   'name',
    #   # give the title a different value than implied by the attribute
    #   { title: 'Years', value: 'age' },
    #   # allows chained expressions like ['friends', 'count'] etc
    #   { title: 'Address', value: ['address'] },
    #   # if no value key is given then we treat it as a full on Ant Table
    #   # column description.  If no title is given it will be the humanized key.
    #   { key: :action, render: method(:delete_btn) }
    #   # a falsy value will be ignored
    # ]

    # the optional expand_row event will receive the record,
    # and should return a react element to display
    fires :expand_row

    # any other params to pass to Ant::Table
    others :etc

    before_update do
      # typically columns will not change, so we cache the last value computed
      # and only recompute if columns actually changes
      @normalized_columns = nil unless @columns == columns
      @columns = columns
    end

    def normalized_columns
      @normalized_columns ||= columns.collect do |column|
        normalize_column column if column
      end.compact
    end

    def get_data(r, c)
      # during the conversion from ruby hash to json object, nil will be converted
      # to null.  Coming back it doesn't work, since JS null has no properties.  So
      # we have this little helper function to grab the value and check it for null.
      v = `r[#{c[:dataIndex]}]`
      v = nil if `v == null`
      v
    end

    def set_title_and_value(column, c)
      if column[:value]
        c[:title] ||= column[:value].humanize
        c[:value] = column[:value].split('.')
      else
        c[:title] ||= c[:key].humanize if c[:key]
      end
    end

    def camelize_keys(column, c)
      c.keys.each { |key| c[key.camelize(:lower)] = c[key] }
    end

    def set_data_index(column, c)
      c[:dataIndex] ||= c[:value].join('-') if c[:value]
    end

    def wrap_render_proc(column, c)
      c[:render] &&=
        ->(_, r, i) { column[:render].call( `r['_record']`, i).to_n }
    end

    def wrap_filter_proc(column, c)
      if column[:filter]
        c[:onFilter] = ->(v, r) { column[:filter].call(v, `r['_record']`) }
      elsif column[:filters]
        c[:onFilter] = ->(v, r) { get_data(r, c) == v }
      end
    end

    def wrap_sorter_proc(column, c)
      return unless column[:sorter]

      if column[:sorter].respond_to? :call
        c[:sorter] = ->(a, b, o) { column[:sorter].call(`a['_record']`, `b['_record']`, o) }
      else
        c[:sorter] = ->(a, b) { get_data(a, c) <=> get_data(b, c) }
      end
    end

    def normalize_column(column)
      return { title: column.humanize, value: column.split('.') } unless column.is_a?(Hash)

      column.dup.tap do |c|
        set_title_and_value(column, c)
        wrap_render_proc(column, c)
        camelize_keys(column, c)
        set_data_index(column, c)
        wrap_filter_proc(column, c)
        wrap_sorter_proc(column, c)
      end
    end

    def gather_values(record)
      normalized_columns.collect do |column|
        [
          column[:value].join('-'),
          column[:value].inject(record) { |value, expr| value.send(expr) }
        ] if column[:value]
      end.compact
    end

    def format_data_source
      records.each_with_index.collect do |record, i|
        # this works around issue https://github.com/hyperstack-org/hyperstack/issues/254
        columns.each { |column| column[:render]&.call(record, i)&.as_node rescue nil}
        expand_row!(record, i).as_node rescue nil

        # its critical that the key is a string for Ant::Table to work
        Hash[[[:key, record.to_key.to_s], [:_record, record]] + gather_values(record)]
      end
    end

    render do
      Ant::NativeTable(
        etc,
        accordion && { expandedRowKeys: @expanded_row_keys || [] },
        dataSource: format_data_source.to_n,
        columns: normalized_columns.to_n
      ) # if expand_row handler is provided add the expandedRowRender
      .on(props[:on_expand_row] && '<expandedRowRender>') do |r, i|
        # the above looks a little clunky - see https://github.com/hyperstack-org/hyperstack/issues/247
        # which would give us expand_row_provided?
        expand_row!(r[:_record], i).to_n
      end
      .on(accordion && '<onExpandedRowsChange>') do |keys|
        mutate @expanded_row_keys = keys[-1..-1]
      end

    end
  end
end
