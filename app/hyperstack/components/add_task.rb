class AddTask < HyperComponent

  param owner: nil

  before_mount { @new_task = Task.new(owner_id: owner&.id) }

  def title_field
    Ant::Form::Item(label: 'Task') do
      Ant::Input(value: @new_task.title)
      .on(:change) { |e| @new_task.title = e.target.value }
    end
  end

  def priority_field
    Ant::Form::Item(label: 'Priority') do
      Ant::Select(style: { width: 120 }, value: @new_task.priority.to_s) do
        Task::PRIORITIES.each do |priority|
          Ant::Select::Option(value: priority) { priority }
        end
      end.on(:change) { |value| @new_task.priority = value }
    end
  end

  def owner_field
    owners = owner ? [owner] : Person.all
    Ant::Form::Item(label: 'Owner') do
      Ant::Select(style: { width: 120 }, value: @new_task.owner_id.to_s) do
        owners.each do |person|
          Ant::Select::Option(value: person.id.to_s) { person.name }
        end
      end.on(:change) { |value| @new_task.owner_id = value }
    end
  end

  def valid?
    @new_task.title.present? && @new_task.owner_id.present? && @new_task.priority.present?
  end

  def add_task_button
    Ant::Button(type: :primary, disabled: !valid?) do
      'Add Task'
    end.on(:click) do
      @new_task.save
      mutate @new_task = Task.new(owner_id: owner&.id)
    end
  end

  render do
    Ant::Form(layout: :inline) do
      title_field
      priority_field
      owner_field
      add_task_button
    end
  end
end
