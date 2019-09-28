class ShowTasks < HyperComponent

  param owner: nil  # optionally specify which owner to show tasks for

  def update_complete_state(task)
    Ant::Checkbox(checked: task.completed.to_n)  # to_n eliminates a bogus warning while data is loading, its not really needed...
    .on(:change) { task.update(completed: !task.completed) }
  end

  def delete_task(task)
    Ant::Button(type: :danger) { 'delete' }.on(:click) { task.destroy }
  end

  def columns
    @columns ||= [
      { value: :title },
      # only add the owner column if we don't know the owner
      !owner && { title: 'Owner', value: 'owner.name' },
      {
        key: :completed,
        render: method(:update_complete_state),
        filters: [{text: :complete, value: true}, {text: :incomplete, value: false}],
        filter_multiple: false,
        filter: ->(value, record) { record.completed == value }
      },
      { key: :action, render: method(:delete_task) }
    ]
  end

  def tasks
    @tasks ||= owner ? owner.tasks : Task.all
  end

  DIV do
    Ant::Table(records: tasks, columns: columns)
    AddTask(owner: owner)
  end
end
