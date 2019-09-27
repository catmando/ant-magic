class Person < ApplicationRecord
  # so you can actually see the spinner, slow things down.
  # comment this line out to go full speed ahead
  default_scope { sleep 0.03; self }
  # note that because of threading etc, sleep time is very
  # inaccurate, you may have to adjust the time on your machine
  has_many :tasks, foreign_key: :owner_id
end
