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

# patch for issue https://github.com/hyperstack-org/hyperstack/issues/256

module Hyperstack
  module Internal
    module Component
      class WhileLoadingWrapper < RescueWrapper
        render do
          if @waiting_on_resources && !quiet?
            RenderingContext.raise_if_not_quiet = false
          else
            @waiting_on_resources = false
            @Child.instance_eval do
              mutate if @__hyperstack_while_loading_waiting_on_resources
              @__hyperstack_while_loading_waiting_on_resources = false
            end
            RenderingContext.raise_if_not_quiet = self
          end
          RescueMetaWrapper(children_elements: @ChildrenElements)
        end

        send("_before_mount_callbacks").clear #{callback_name}_callbacks

        before_mount do
          @Child.class.rescues RenderingContext::NotQuiet do |e|
            e.while_loading_rescue_wrapper.instance_variable_set(:@waiting_on_resources, true)
            @__hyperstack_while_loading_waiting_on_resources = true
          end
        end

        after_render do
          RenderingContext.raise_if_not_quiet = false
        end
      end
    end
  end
end

module Hyperstack
  module Internal
    module Component
      class RenderingContext
        class NotQuiet < Exception
          attr_reader :while_loading_rescue_wrapper
          def initialize(component, wrapper)
            @while_loading_rescue_wrapper = wrapper
            super("#{component} is waiting on resources - this should never happen")
          end
        end
        class << self
          attr_accessor :waiting_on_resources

          def raise_if_not_quiet?
            @while_loading_rescue_wrapper
          end

          def raise_if_not_quiet=(wrapper)
            @while_loading_rescue_wrapper = wrapper
          end

          def quiet_test(component)
            return unless component.waiting_on_resources && raise_if_not_quiet? #&& component.class != RescueMetaWrapper <- WHY  can't create a spec that this fails without this, but several fail with it.
            raise NotQuiet.new(component, @while_loading_rescue_wrapper)
          end
        end
      end
    end
  end
end
