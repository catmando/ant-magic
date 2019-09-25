class AddRecord < HyperComponent

  render do
    Ant::Form(layout: :inline) do
      Ant::Form::Item(label: 'Name') do
        Ant::Input(ref: set_jq(:name))
      end
      Ant::Form::Item(label: 'Age') do
        Ant::Input(ref: set_jq(:age))
      end
      Ant::Form::Item(label: 'Address') do
        Ant::Input(ref: set_jq(:address))
      end
      Ant::Button(type: :primary, htmlType: :submit) do
        'Add Person'
      end
    end.on(:submit) do |e|
      e.prevent_default
      Person.create(name: @name.value, age: @age.value, address: @address.value)
      @name.value = @age.value = @address.value = ''
    end
  end
end
