class Person < ApplicationRecord
  has_many :tasks, foreign_key: :owner_id, dependent: :destroy

  scope :sorted_by_tasks_incomplete_count,
        lambda { |order|
          joins("LEFT JOIN (#{Task.incomplete.to_sql}) AS tasks ON people.id = tasks.owner_id")
            .group(:id)
            .order("COUNT(tasks.id) #{order}")
        },
        joins: :tasks # inform Hyperstack client that the scope joins with tasks
end
