class AddPerson < HyperComponent
  before_mount { @new_person = Person.new }

  def form_item(attr)
    Ant::Form::Item(label: attr.humanize) do
      Ant::Input(value: @new_person[attr])
      .on(:change) { |e| @new_person[attr] = e.target.value }
    end
  end

  render do
    Ant::Form(layout: :inline) do
      form_item :name
      form_item :age
      form_item :address
      Ant::Button(type: :primary) { 'Add Person' }
      .on(:click) do
        @new_person.save
        mutate @new_person = Person.new
      end
    end
  end
end
