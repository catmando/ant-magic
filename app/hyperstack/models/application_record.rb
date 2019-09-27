class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  regulate_scope all: :always_allow
  # these methods belong in hyper-model see issue ....
  # datetime, date, boolean, float, integer, string
  def column_type(attr)
    backing_record.column_type(attr)
  end
  def self.column_type(attr)
    ReactiveRecord::Base.column_type(columns_hash[attr])
  end
end

module ReactiveRecord
  class Base
    class DummyValue < BasicObject
      def build_default_value_for_boolean
        @column_hash[:default] == '1' || @column_hash[:default] == true || @column_hash[:default] == 1
      end
    end
  end
end
