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
      { value: 'name', sorter: ->(a, b) { (a.name <=> b.name) } }, # specify the method
      { title: 'Years', value: 'age', sorter: true,
        filters: [{text: 'under 50', value: true}], filter: ->(value, record) { !value || record.age.to_i < 50 } }, # or use the default sort function
      { title: 'Address', value: 'address' },
      {
        title: 'Open Tasks', value: 'tasks.incomplete.count',
        sorter: :remote#, filters: [{text: 'with open tasks', value: true}],
        #filter: ->(value, record) { !value || record.tasks.incomplete.count.positive? }
      },
      { key: :action, render: method(:delete_person) }
    ]
  end

  before_mount { @sort_by = :sorted_by_tasks_incomplete_count; @sort_order = :ASC }

  define_method :handle_change do |p, f, s|
    field = s[:field]
    order = s[:order]
    # field = `s['field'] || #{nil}`
    # order = `s['order'] || #{nil}`

    puts "sorting on #{field&.underscore} #{order}"
    next unless field == 'tasks-incomplete-count'

    @sort_by = "sorted_by_#{field.underscore}"
    @sort_order = order == 'descend' ? :DESC : :ASC
    mutate
  end

  DIV do
    puts "Person.send(#{@sort_by}, #{@sort_order})"
    Ant::Table(:accordion, records: Person.send(@sort_by, @sort_order), columns: columns) #, onChange: method(:handle_change).to_proc)
    .on(:expand_row) { |owner| ShowTasks(owner: owner) }
    .on(:change) do |p, f, s|
      handle_change(p, f, s)
    end
    AddPerson()
  end
end
