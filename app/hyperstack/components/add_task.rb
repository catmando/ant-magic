class AddTask < HyperComponent

  param owner: nil

  def reset_state
    mutate @title = '', @owner_id = (owner&.id || '')
  end

  before_mount :reset_state

  def title_field
    Ant::Form::Item(label: 'Task') do
      Ant::Input(value: @title)
      .on(:change) { |e| mutate @title = e.target.value }
    end
  end

  def owner_field
    owners = owner ? [owner] : Person.all
    Ant::Form::Item(label: 'Owner') do
      Ant::Select(style: { width: 120 }, value: @owner_id.to_s) do
        owners.each do |person|
          `console.log('person.id.to_n = "'+#{person.id.to_s}+'"')`
          Ant::Select::Option(value: person.id.to_s) { person.name }
        end
      end.on(:change) { |value| mutate @owner_id = value }
    end
  end

  def add_task_button
    Ant::Button(type: :primary, disabled: @title.blank? || @owner_id.blank?) do
      'Add Task'
    end.on(:click) do
      Task.create(title: @title, owner_id: @owner_id)
      reset_state
    end
  end

  render do
    Ant::Form(layout: :inline) do
      title_field
      owner_field
      add_task_button
    end
  end
end
