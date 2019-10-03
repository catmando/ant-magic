class ShowTasks < HyperComponent
  param owner: nil  # optionally specify which owner to show tasks for

  def update_complete_state(task)
    Ant::Checkbox(checked: task.completed.to_n)  # to_n eliminates a bogus warning while data is loading, its not really needed...
    .on(:change) { task.update(completed: !task.completed) }
  end

  def actions(task)
    DIV do
      Ant::Button(type: :danger) { 'delete' }.on(:click) { task.destroy }
      if task.owner
        Ant::Button(type: :danger) { 'unlink' }.on(:click) { task.update(owner_id: nil) }
      end
    end
  end

  def priority_filter
    Task::PRIORITIES.collect { |p| {text: p, value: p} }
  end

  def columns
    @columns ||= [
      { value: :title },
      # only add the owner column if we don't know the owner
      { value: :priority, filters: priority_filter, sort: true},
      !owner && { title: 'Owner', value: 'owner.name' },
      {
        key: :completed,
        render: method(:update_complete_state),
        filters: [{text: :complete, value: true}, {text: :incomplete, value: false}],
        filter_multiple: false,
        filter: ->(value, record) { record.completed == value }
      },
      { key: :action, render: method(:actions) }
    ]
  end

  def tasks
    @tasks ||= owner ? owner.tasks : Task.all
  end

  DIV do
    Ant::Table(records: tasks, columns: columns)
    AddTask(owner: owner) unless owner == :none
  end
end
