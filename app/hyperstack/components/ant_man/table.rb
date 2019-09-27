module AntMan
  # Wrapper for Ant Table component
  class Table < ::HyperComponent
    param :records # any collection of ActiveRecord like objects
    param :columns # array of column descriptions (see below for details)

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
    # ]

    fires :expand_row # the optional expand_row event will receive the record,
                      # and should return a react element to display


    others :etc       # any other params to pass to Ant::Table


    before_update do
      # typically columns will not change, so we cache the last value computed
      # and only recompute if columns actually changes
      @normalized_columns = @formatted_columns = nil unless @columns == columns
      @columns = columns
    end

    def normalized_columns
      @normalized_columns ||= columns.collect do |column|
        normalize_column column
      end
    end

    def normalize_column(column)
      if !column.is_a?(Hash)
        { title: column.humanize, value: [column] }
      elsif column[:value].is_a? Array
        column
      elsif column[:value]
        { title: column[:title], value: [column[:value]] }
      else
        normalize_pass_through_column column
      end
    end

    def normalize_pass_through_column(column)
      column.dup.tap do |c|
        c[:render] &&=
          ->(_, _r, i) { column[:render].call(records[i], i).to_n }
        c[:title] ||=
          c[:key].humanize
      end
    end

    def formatted_columns
      @formatted_columns ||= normalized_columns.collect do |column|
        if column[:value]
          {
            title:     column[:title],
            dataIndex: column[:value].join('-')
          }
        else
          column
        end
      end
    end

    def gather_values(record)
      normalized_columns.collect do |column, i|
        [
          column[:value].join('-'),
          column[:value].inject(record) { |value, expr| value.send(expr) }
        ] if column[:value]
      end.compact
    end

    def format_data_source
      records.collect do |record, i|
        # this works around issue https://github.com/hyperstack-org/hyperstack/issues/254
        columns.each { |column| column[:render]&.call(record)&.as_node }
        expand_row!(record).as_node rescue nil
        
        # its critical that the key is a string for Ant::Table to work
        Hash[[[:key, record.to_key.to_s]] + gather_values(record, i)]
      end
    end

    render do

      Ant::Table(
        etc,
        dataSource: format_data_source.to_n,
        columns: formatted_columns.to_n,
      ) # if expand_row handler is provided add the expandedRowRender
      .on(props[:on_expand_row] && '<expandedRowRender>') do |_, i|
        # the above looks a little clunky - see https://github.com/hyperstack-org/hyperstack/issues/247
        # which would give us expand_row_provided?
        expand_row!(records[i]).to_n
      end
    end
  end
end
