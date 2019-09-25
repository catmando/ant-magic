module AntMan
  # Wrapper for Ant Table component
  class Table < ::HyperComponent
    param :records # any collection of ActiveRecord like objects
    param :columns # array of column descriptions (see below for details)

    others :etc    # any other params to pass to Ant::Table

    # each column is described in one of three ways:

    # [
    #   :simple_attribute,  # will fetch simple_attribute from the record (i.e. record.simple_attribute)
    #                       # the header will be the humanized value i.e. Simple Attribute
    #   {title: 'Custom Title', value: :simple_attribute },    # if you want a different title
    #   {title: 'Count of Friends', value: [:friends, :count]} # if you want a complex chain of expressions
    # ]

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
          ->(_, r, i) { column[:render].call(c[:key], `#{r}.key`, i).to_n }
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
      normalized_columns.collect do |column|
        [
          column[:value].join('-'),
          column[:value].inject(record) { |value, expr| value.send(expr) }
        ] if column[:value]
      end.compact
    end

    def format_data_source
      records.collect do |record|
        Hash[[[:key, record]] + gather_values(record)]
      end
    end

    render do
      Ant::Table(
        etc,
        dataSource: format_data_source.to_n,
        columns: formatted_columns.to_n
      )
    end
  end
end
