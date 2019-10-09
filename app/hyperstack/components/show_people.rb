class ShowPeople < HyperComponent
  def delete_person(person)
    title = "#{person.name} has #{pluralize(person.tasks.incomplete.count, 'task')} "\
            'open, are you sure you want to delete?'
    Ant::Popconfirm(placement: :left, title: title, okText: 'Yes', cancelText: 'No') do
      Ant::Button(type: :danger) { 'Delete' }
    end.on(:Confirm) { person.destroy }
  end

  def columns
    @columns ||= [
      { value: 'name', sorter: ->(a, b) { (a.name <=> b.name) } }, # specify the sort method
      {
        title: 'Years', value: 'age', sorter: true, # or use the default sort function
        filters: [{ text: 'under 50', value: true }],
        filter: ->(value, record) { !value || record.age.to_i < 50 }
      },
      { title: 'Address', value: 'address' },
      {
        title: 'Open Tasks', value: 'tasks.incomplete.count',
        sorter: :remote
      },
      { key: :action, render: method(:delete_person) }
    ]
  end

  # demonstrates how to sort server side.
  # which we do only for the tasks-incomplete-count column

  before_mount do
    @sort_by = :sorted_by_tasks_incomplete_count
    @sort_order = :ASC
  end

  define_method :handle_change do |p, f, s|
    field = s[:field]
    order = s[:order]
    next unless field == 'tasks-incomplete-count'

    mutate do
      @sort_by = "sorted_by_#{field.underscore}"
      @sort_order = order == 'descend' ? :DESC : :ASC
    end
  end

  def sorted_records
    Person.send(@sort_by, @sort_order)
  end

  DIV do
    Ant::Table(:accordion, records: sorted_records, columns: columns)
    .on(:expand_row) { |owner| ShowTasks(owner: owner) }
    .on(:change) { |p, f, s| handle_change(p, f, s) }
    AddPerson()
  end
end
