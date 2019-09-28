# sample App showing how to use Ant  Design with Hyperstack
class App < HyperComponent
  DIV(style: { padding: 50 }) do
    Ant::Collapse :accordion do
      Ant::Collapse::Panel(header: 'Tasks', key: 'Tasks') do
        ShowTasks()
      end
      Ant::Collapse::Panel(header: 'People', key: 'People') do
        ShowPeople()
      end
    end
  end
end
