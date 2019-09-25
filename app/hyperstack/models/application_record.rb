class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  regulate_scope all: :always_allow
end
