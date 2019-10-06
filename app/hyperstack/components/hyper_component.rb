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

module Hyperstack
  def self.handle_webpack
    puts "************** Running patched Hyperstack.handle_webpack ******************"
    return unless defined? Webpacker

    webpack_imports = %w[client_only.js client_and_server.js client_only.css client_and_server.css].collect do |file|
      Webpacker.manifest.lookup(file)&.split('/')&.last
    end.compact
    puts "found these manifests #{webpack_imports}"
    return if webpack_imports.empty?


    cancel_webpack_imports
    webpack_imports.each do |file|
      puts "inserting > import #{file}, client_only: #{!!(file =~ '^client_only')}, at_head: true"
      import file, client_only: !!(file =~ '^client_only'), at_head: true
    end
    # import client_only_manifest.split("/").last, client_only: true, at_head: true if client_only_manifest
    # import client_and_server_manifest.split("/").last, at_head: true if client_and_server_manifest
  end
end
