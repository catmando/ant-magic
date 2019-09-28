class ShowPeople < HyperComponent
  include Hyperstack::Component::WhileLoading
  def delete_person(person)
    title = "#{person.name} has #{pluralize(person.tasks.incomplete.count, 'task')} "\
            "open, are you sure you want to delete?"
    Ant::Popconfirm(placement: :left, title: title, okText: 'Yes', cancelText: 'No') do
      Ant::Button(type: :danger) { 'Delete' }
    end.on(:Confirm) { person.destroy }
  end

  def columns
    @columns ||= [
      { value: 'name', sorter: ->(a, b) { (a.name <=> b.name) } }, # specify the method
      { title: 'Years', value: 'age', sorter: true }, # or use the default sort function
      { title: 'Address', value: 'address' },
      {
        title: 'Open Tasks', value: 'tasks.incomplete.count',
        sorter: true, filters: [{text: 'with open tasks', value: true}],
        filter: ->(value, record) { !value || record.tasks.incomplete.count.positive? }
      },
      { key: :action, render: method(:delete_person) }
    ]
  end

  DIV do
    next Ant::Spin() unless resources_loaded?

    Ant::Table(:accordion, records: Person.all, columns: columns)
    .on(:expand_row) { |owner| ShowTasks(owner: owner) }
    AddPerson()
  end
end
