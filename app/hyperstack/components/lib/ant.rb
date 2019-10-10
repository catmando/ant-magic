require 'delegate'
# Wrap the Ant Library
# Most of the Ant Components can be used as is.
# However Ant::Table needs some massaging of the data
# to make it easier to use, and so it can be used directly with Active Records
class Ant < Hyperstack::Component::NativeLibrary
  imports 'Ant'
  rename Table: :NativeTable # access the original Table via :NativeTable

  # Wrapper for Ant Table component so it works with AR records
  class Table < HyperComponent

    param :records          # any collection of ActiveRecord like objects
    param :columns          # array of column descriptions (see below for details)
    param accordion: false  # true if only one row can be expanded at a time

    # [
    #   # columns can can simply be the name of the attribute.  The column header
    #   # will be the humanized attribute name (i.e. Name)
    #   'name',
    #   # give the title a different value than implied by the attribute
    #   { title: 'Years', value: 'age' },
    #   # value can be a chain of expressions
    #   { title: 'Address', value: 'friends.count'] },
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
      @normalized_columns = @native_columns = nil unless @columns == columns
      @columns = columns
    end

    def normalized_columns
      @normalized_columns ||= columns.collect do |column|
        NormalizedColumn.new(column) if column
      end.compact
    end

    # NormalizedColumn is a hash that has been converted so that all keys and values
    # are as expected by NativeTable.
    class NormalizedColumn < ::SimpleDelegator
      def initialize(column)
        if !column.is_a?(::Hash)
          super title: column.humanize, value: column.split('.')
        else
          super column.dup
          @column = column
          normalize!
        end
      end

      private

      def normalize!
        set_title_and_value
        wrap_render_proc
        camelize_keys
        set_data_index
        wrap_filter_proc
        wrap_sorter_proc
      end

      def set_title_and_value
        if @column[:value]
          self[:title] ||= @column[:value].humanize
          self[:value] = @column[:value].split('.')
        elsif @column[:key]
          self[:title] ||= self[:key].humanize
        end
      end

      def wrap_render_proc
        self[:render] &&= ->(_, _r, i) { @column[:render].call( `_r['_record']`, i).to_n }
      end

      def camelize_keys(_, c)
        keys.each { |key| self[key.camelize(:lower)] = self[key] }
      end

      def set_data_index
        self[:dataIndex] ||= self[:value].join('-') if self[:value]
      end

      def get_data(r)
        # during the conversion from ruby hash to json object, nil will be converted
        # to null.  Coming back it doesn't work, since JS null has no properties.  So
        # we have this little helper function to grab the value and check it for null.
        `r[#{self[:dataIndex]}] || #{nil}`
      end

      def wrap_filter_proc
        if @column[:filter]
          self[:onFilter] = ->(v, r) { @column[:filter].call(v, `r['_record']`) }
        elsif @column[:filters]
          self[:onFilter] = ->(v, r) { get_data(r) == v }
        end
      end

      def wrap_sorter_proc
        return unless @column[:sorter]

        if @column[:sorter].respond_to? :call
          self[:sorter] = ->(a, b, o) { @column[:sorter].call(`a['_record']`, `b['_record']`, o) }
        elsif self[:sorter] == :remote
          self[:sorter] = true
        else
          self[:sorter] = ->(a, b) { get_data(a) <=> get_data(b) }
        end
      end
    end

    NATIVE_COLUMN_KEYS = %i[
      align className colSpan dataIndex defaultSortOrder filterDropdown
      filterDropdownVisible filtered filteredValue filterIcon filterMultiple
      filters fixed key render sorter sortOrder sortDirections title width
      onCell onFilter onFilterDropdownVisibleChange
    ]

    def native_columns
      # filter out all columns that are not expected by the NativeTable
      # and convert to hash to a native json object
      @native_columns ||= normalized_columns.collect do |column|
        column.dup.tap do |native_column|
          native_column.delete_if { |k, _v| !NATIVE_COLUMN_KEYS.include?(k) }
        end
      end.to_n
    end

    def current_data_source
      # Get the current LOADED data source formatted correctly for the native Table
      # component.  If the data is still loading, then fall back to the previous
      # data (or an empty data set), and set the loading flag.

      # Hyperstack will automatically re-render the component when all the data is
      # loaded, which will rerun this method.
      new_data_source = format_data_source
      if data_source_loaded?(new_data_source)
        @previous_data_source = @current_data_source
        @current_data_source = new_data_source.to_n
        { dataSource: @current_data_source }
      else
        { dataSource: @previous_data_source || [], loading: true }
      end
    end

    def data_source_loaded?(data_source)
      # The loading? method will return true for any object that is
      # waiting to be loaded.
      !data_source.detect { |column| column.values.detect(&:loading?) }
    end

    def format_data_source
      # Retrieve a hash of all the values from active record models specified by the
      # normalized columns.
      # The resulting hash will be in the form
      # { :key => record.to_key.to_s, :_record => record, key1 => value1, ... keyN => valueN }
      records.each_with_index.collect do |record, i|
        # the following works around issue https://github.com/hyperstack-org/hyperstack/issues/254
        columns.each { |column| column[:render]&.call(record, i)&.as_node rescue nil}
        expand_row!(record, i).as_node rescue nil

        # its critical that the key is a string for Ant::Table to work
        Hash[[[:key, record.to_key.to_s], [:_record, record]] + gather_values(record)]
      end
    end

    def gather_values(record)
      # Retrieve an array of pairs (ready to convert to a hash) of key, value pairs
      normalized_columns.collect do |column|
        next unless column[:value]

        [
          column[:value].join('-'),
          column[:value].inject(record) { |value, expr| value.send(expr) if value }
        ]
      end.compact
    end

    def expanded_row_keys
      # Handles accordion mode (which is extension provided by the wrapper)

      # Ant::NativeTable takes an optional expandedRowKeys parameter which is an
      # array of rows to be expanded, and fires the onExpandedRowsChange callback
      # when ever the user expands or collapses a row.

      # Normally Ant::NativeTable allows multiple rows to be open, so it will
      # push a new row key on the end of keys list when a row is expanded,
      # and remove the key when the row is collapsed. In accordion mode we keep
      # the value of @expanded_row_keys as the last row expanded, or nil if all
      # rows are collapsed.

      return unless accordion

      {
        expandedRowKeys: @expanded_row_keys || [],
        onExpandedRowsChange: ->(keys) { mutate @expanded_row_keys = keys[-1..-1] }
      }
    end

    render(DIV) do
      Ant::NativeTable(
        # note that Hypermesh will merge all parameters passed to a component as a single
        # hash, ignoring any falsy values.  This is handy to build the parameter list
        # in a HOC like this
        etc,
        expanded_row_keys,
        current_data_source,
        columns: native_columns
      ) # if expand_row handler is provided add the expandedRowRender callback
      .on(props[:on_expand_row] && '<expandedRowRender>') do |r, i|
        # the above looks a little clunky - see https://github.com/hyperstack-org/hyperstack/issues/247
        # which would give us expand_row_provided?
        expand_row!(r[:_record], i).to_n
      end
    end
  end
end
