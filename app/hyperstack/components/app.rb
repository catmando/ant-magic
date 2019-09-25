# sample App showing how to use Ant Table including a while loading spinner
class App < HyperComponent
  # WhileLoading causes automatic rerender if data is loading
  include Hyperstack::Component::WhileLoading
  # experimental module eliminates need for the render method
  include Hyperstack::Component::FreeRender

  # define a method to generate the delete button which we will pass along
  # as the "value" of the Action column below

  def self.delete_btn(_text, js_data)
    # The AntMan wrapper will add a "key" in each js data set pointing back to
    # the original active record instance.  We can use this to figure out which
    # record we are talking about, and destroy it using the normal AR destroy method.
    Ant::Button(type: :danger) { 'delete' }
    .on(:click) { `js_data.key`.destroy }
    .to_n
    # because we are passing the button back to Ant we have to apply `to_n`
  end

  # Define the columns to display.  Each element in the array defines a column
  # Columns can simply name the desired attribute, or can be more complex.
  # Each item gets converted to the Ant expected format by the AntMan::Table
  # component.

  COLUMNS = [
    'name',                                   # simple format, the title will be the humanized attribute name
    { title: 'Years', value: 'age' },         # give the title a different value than implied by the attribute
    { title: 'Address', value: ['address'] }, # allows chained expressions like ['friends', 'count'] etc
    { title: 'Action',                        # anything without a value key will be passed along to Ant without
      key: :action,                           # any processing
      render: method(:delete_btn).to_proc }
  ]

  # The WhileLoading module will cause the component to render 3 times:
  # The initial render will attempt to display the table, but will fail because data is loading
  # then the second render will display the spinner
  # finally when the data is loaded we will render a 3rd time with the actual data

  # The first render which is never actually displayed is what collects the graph of data
  # that we will need.

  # Note that the experimental "FreeRender" module allows us to skip the render method.

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
