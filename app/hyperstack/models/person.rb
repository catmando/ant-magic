class Person < ApplicationRecord
  has_many :tasks, foreign_key: :owner_id, dependent: :destroy
  scope :sorted_by_tasks_incomplete_count, (
    lambda do |order|
      find_by_sql(
        'SELECT people.* FROM people LEFT JOIN ('\
        '  SELECT tasks.owner_id as owner_id, COUNT(tasks.owner_id) as task_count '\
        '  FROM tasks'\
        '  WHERE tasks.completed = false'\
        '  GROUP BY tasks.owner_id) as incomplete_task_counts '\
        "ON people.id = incomplete_task_counts.owner_id ORDER BY task_count #{order}"
      )
    end
  )

  # def destroy(*args, &block)
  #   Promise.when(tasks.collect(&:destroy)).then { super }
  # end if RUBY_ENGINE == 'opal'

end

# class NilClass
#   def incomplete(*args, &block)
#     debugger
#     nil
#   end
# end
