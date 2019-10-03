# app/hyperstack/hyper_component.rb
class HyperComponent
  # All component classes must include Hyperstack::Component
  include Hyperstack::Component
  # The Observable module adds state handling
  include Hyperstack::State::Observable
  # The following turns on the new style param accessor
  # i.e. param :foo is accessed by the foo method
  param_accessor_style :accessors
  # experimental module eliminates need for the render method
  include Hyperstack::Component::FreeRender
end

# patch for https://github.com/hyperstack-org/hyperstack/issues/255
module ReactiveRecord
  module Getters
    def get_has_many(assoc, reload = nil)
      getter_common(assoc.attribute, reload) do |_has_key, attr|
        if new?
          @attributes[attr] = Collection.new(assoc.klass, @ar_instance, assoc)
        else
          sync_attribute attr, Collection.new(assoc.klass, @ar_instance, assoc, *vector, attr)
        end
        # getter_common returns nil on destroyed records, so we return empty collection instead
      end || Collection.new(assoc.klass, @ar_instance, assoc)
    end
  end
end
