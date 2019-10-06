Hyperstack.cancel_import 'react/react-source-browser' # bring your own React and ReactRouter via Yarn/Webpacker
Hyperstack.import 'hyperstack/hotloader', client_only: true if Rails.env.development?
# set the component base class

Hyperstack.component_base_class = 'HyperComponent' # i.e. 'ApplicationComponent'

# prerendering is default :off, you should wait until your
# application is relatively well debugged before turning on.

Hyperstack.prerendering = :off # or :on

# transport controls how push (websocket) communications are
# implemented.  The default is :action_cable.
# Other possibilities are :pusher (see www.pusher.com) or
# :simple_poller which is sometimes handy during system debug.

Hyperstack.transport = :action_cable # or :none, :pusher,  :simple_poller

# add this line if you need jQuery AND ARE NOT USING WEBPACK
Hyperstack.import 'hyperstack/component/jquery', client_only: true

# change definition of on_error to control how errors such as validation
# exceptions are reported on the server
module Hyperstack
  def self.on_error(operation, err, params, formatted_error_message)
    ::Rails.logger.debug(
      "#{formatted_error_message}\n\n" +
      Pastel.new.red(
        'To further investigate you may want to add a debugging '\
        'breakpoint to the on_error method in config/initializers/hyperstack.rb'
      )
    )
  end
end if Rails.env.development?

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
