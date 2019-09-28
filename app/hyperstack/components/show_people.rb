class ShowPeople < HyperComponent
  def delete_person(person)
    title = "#{person.name} has #{pluralize(person.tasks.incomplete.count, 'task')} "\
            "open, are you sure you want to delete?"
    Ant::Popconfirm(placement: :left, title: title, okText: 'Yes', cancelText: 'No') do
      Ant::Button(type: :danger) { 'Delete' }
    end.on(:Confirm) { person.destroy }
  end

  def columns
    @columns ||= [
      'name',
      { title: 'Years', value: 'age' },
      { title: 'Address', value: 'address' },
      { title: 'Open Tasks', value: 'tasks.incomplete.count'},
      { key: :action, render: method(:delete_person) }
    ]
  end

  DIV do
    Ant::Table(:accordion, records: Person.all, columns: columns)
    .on(:expand_row) { |owner| ShowTasks(owner: owner) }

    AddPerson()
  end
end
