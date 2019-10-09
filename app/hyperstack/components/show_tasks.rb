class ShowTasks < HyperComponent
  param owner: nil # optionally specify which owner to show tasks for

  def update_complete_state(task)
    Ant::Checkbox(checked: task.completed)
    .on(:change) { task.update(completed: !task.completed) }
  end

  def actions(task)
    DIV do
      Ant::Button(type: :danger) { 'delete' }.on(:click) { task.destroy }
    end
  end

  def priority_filter
    Task::PRIORITIES.collect { |p| { text: p, value: p } }
  end

  COMPLETED_FILTERS = [
    { text: :complete, value: true },
    { text: :incomplete, value: false }
  ]

  def columns
    @columns ||= [
      { value: :title },
      { value: :priority, filters: priority_filter, sort: true },
      # only add the owner column if we don't know the owner
      !owner && { title: 'Owner', value: 'owner.name' },
      {
        key: :completed,
        render: method(:update_complete_state),
        filters: COMPLETED_FILTERS,
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
