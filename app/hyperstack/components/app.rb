# sample App showing how to use Ant Table including a while loading spinner
class App < HyperComponent
  # WhileLoading causes automatic rerender if data is loading
  include Hyperstack::Component::WhileLoading
  # experimental module eliminates need for the render method
  include Hyperstack::Component::FreeRender

  # define a method to generate the delete button which we will pass along
  # as the "value" of the Action column below

  def self.delete_btn(_key, record, _index)
    Ant::Button(type: :danger) { 'delete' }.on(:click) { record.destroy }
  end

  # Define the columns to display.  Each element in the array defines a column
  # Columns can simply name the desired attribute, or can be more complex.
  # Each item gets converted to the Ant expected format by the AntMan::Table
  # component.

  COLUMNS = [
    # columns can can simply be the name of the attribute.  The column header
    # will be the humanized attribute name (i.e. Name)
    'name',
    # give the title a different value than implied by the attribute
    { title: 'Years', value: 'age' },
    # allows chained expressions like ['friends', 'count'] etc
    { title: 'Address', value: ['address'] },
    # if no value key is given then we treat it as a full on Ant Table
    # column description.  If no title is given it will be the humanized key.
    { key: :action, render: method(:delete_btn) }
  ]

  # The WhileLoading module will cause the component to render 3 times:
  #
  # 1 - The initial render will render to the virtual DOM using dummy data
  #     but will fail before completing the render because data is loading
  # 2 - then the second render will complete and display the spinner
  # 3 - finally when the data is loaded we will render a 3rd time with the
  #     actual data.

  # The first render which is never actually displayed is what collects the
  # graph of data that we will need.

  # Note that the experimental "FreeRender" module allows us to skip the render
  # method.

  DIV(style: { padding: 50 }) do
    if resources_loaded?
      # once resources are loaded display the table
      AntMan::Table(records: Person.all, columns: COLUMNS)
    else
      # otherwise display the standard Ant spinner
      Ant::Spin(size: :large)
    end
    AddRecord()
  end
end
