class Task < ApplicationRecord
  belongs_to :owner, class_name: 'Person'
  scope :complete, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
  PRIORITIES = %w[CRITICAL MAJOR ORDINARY]
  scope :with_priority, ->(priority) { where(priority: priority.upcase) }
end
