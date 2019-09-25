# AntMagic

This is a demo of using Ant Design framework within Hyperstack.  You will need git, Rails, bundler, node and yarn installed to proceed.

You should be able to

1. clone the repo,
2. bundle install,
3. yarn install,
3. bundle exec rails db:reset
4. bundle exec foreman start
5. visit localhost:5000

Most of Ant Design is easily accessible to Hyperstack.  Here we use the `Button`, `Spin`, `Form`, `Input`, and `Table` components.

While `Table` is easily accessible, its data input is a plain JSON object, so to allow an easy interface between our ActiveRecord models and Ant Tables, we build a simple `AntMan::Table` wrapper, that uses
a modified Ant Design Table column description to pull the data out of our ActiveRecord collection.

We also demonstrate how to use the `WhileLoading` module to dynamically replace the table component with a spinner while the table's data is
loading.

Like any Hyperstack app, data synchronization between all clients and the server is automatic.
