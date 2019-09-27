# sample App showing how to use Ant Table including a while loading spinner
class App < HyperComponent

  `window.reload = function() { #{Hyperstack::Component::IsomorphicHelpers.load_context} };`


  # Define the columns to display.  Each element in the array defines a column
  # Columns can simply name the desired attribute, or can be more complex.
  # Each item gets converted to the Ant expected format by the AntMan::Table
  # component.

  PERSON_COLUMNS = [
    # columns can can simply be the name of the attribute.  The column header
    # will be the humanized attribute name (i.e. Name)
    'name',
    # give the title a different value than implied by the attribute
    { title: 'Years', value: 'age' },
    # allows chained expressions like ['friends', 'count'] etc
    { title: 'Address', value: ['address'] },

    { title: 'Open Tasks', value: [:tasks, :incomplete, :count]}
  ]


  class ShowTasks < HyperComponent

    include Hyperstack::Component::WhileLoading

    param owner: nil  # optionally specify which owner to show tasks for

    before_mount { @render_count = 0 }

    # before_mount do
    #   @tasks = owner ? owner.tasks : Task.all
    #   @columns = TASK_COLUMNS
    #   @columns = @columns.delete_if { |c| c[:title] == 'Owner' } if owner
    # end

    def self.update_complete_state(task)
      Ant::Checkbox(checked: task.completed.to_n)
      .on(:change) { task.update(completed: !task.completed) }
    end

    # define a method to generate the delete button which we will pass along
    # as the "value" of the Action column below

    def self.delete_task(task)
      Ant::Button(type: :danger) { 'delete' }.on(:click) { task.destroy }
    end

    TASK_COLUMNS = [
      { value: :title },
      { title: 'Owner', value: ['owner', 'name'] },

      # if no value key is given then we treat it as a full on Ant Table
      # column description.  If no title is given it will be the humanized key.

      { key: :completed, render: method(:update_complete_state) },
      { key: :action, render: method(:delete_task) }
    ]

    # The resources_loaded? (from the WhileLoading module) will cause the
    # component to render 3 times:
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

    DIV do
      @render_count += 1
      puts "Show Task #{self.inspect} rendering: resources_loaded: #{resources_loaded?} render_count: #{@render_count} owner: #{owner}"
      @tasks = owner ? Task.owned_by(owner.id) : Task.all
      puts "@tasks = #{@tasks}"
      @columns = TASK_COLUMNS
      @columns = @columns.delete_if { |c| c[:title] == 'Owner' } if owner

      if resources_loaded? && @render_count != 2
        AntMan::Table(records: @tasks, columns: @columns)
        AddTask(owner: owner)
      else
        puts "spinning"
        Ant::Spin()
      end
    end
  end

  class ShowPeople < HyperComponent
    include Hyperstack::Component::WhileLoading
    DIV do
      puts "Show People rendering: resources_loaded: #{resources_loaded?}, expandedRowKeys: #{@expandedRowKeys}"
      if resources_loaded?
        AntMan::Table(records: Person.all, columns: PERSON_COLUMNS, expandedRowKeys: @expandedRowKeys || [])
          .on('<onExpandedRowsChange>') do |keys|
            if keys == @expandedRowKeys
              mutate @expandedRowKeys += keys
            elsif keys.empty?
              mutate @expandedRowKeys&.shift
            else
              mutate @expandedRowKeys = keys[-1..-1]
            end
            puts "new keys = #{keys} @expandedRowKeys set to [#{@expandedRowKeys}]"
          end
          .on(:expand_row) { |owner| ShowTasks(owner: owner) }
        AddPerson()
      else
        Ant::Spin()
      end
    end
  end

  DIV(style: { padding: 50 }) do

    #puts "first persons tasks #{Person.find(21).tasks.collect { |task| task.title }}"
    Ant::Collapse :accordion do
      Ant::Collapse::Panel(header: 'Tasks', key: '1') do
        ShowTasks()
      end
      Ant::Collapse::Panel(header: 'People', key: '2') do
        ShowPeople()
      end
    end
  end
end
