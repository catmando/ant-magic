class Task < ApplicationRecord
  belongs_to :owner, class_name: 'Person'
  scope :complete, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
end
