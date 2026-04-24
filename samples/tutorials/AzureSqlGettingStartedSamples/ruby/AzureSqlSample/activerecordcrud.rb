require 'active_record'
require 'tiny_tds'
require 'activerecord-sqlserver-adapter'
require 'pp'

ActiveRecord::Base.establish_connection(
  :adapter=> "sqlserver",
  :host => "localhost",
  :username => "sa",
  :password => "your_password"
)

#Create new database SampleDB
puts "Drop and create new database 'SampleDB'"
ActiveRecord::Base.connection.drop_database('SampleDB') rescue nil
ActiveRecord::Base.connection.create_database('SampleDB')
ActiveRecord::Base.connection.use_database('SampleDB')

#Create a new table called Tasks
ActiveRecord::Schema.define do
  create_table :tasks, force: true do |t|
    t.string :taskname
    t.string :user
    t.date :duedate
  end
end

class Task < ActiveRecord::Base
end

#Create new tasks and users
Task.create!(taskname:'Install SQL Server 2017 on Windows', user:'Andrea', duedate: '2017-07-01')
Task.create!(taskname:'Upgrade from SQL Server 2014 to 2017', user:'Meet', duedate: '2017-07-01')
Task.create!(taskname:'Write new SQL Server content', user:'Luis', duedate: '2017-07-01')
pp "Created new tasks:"
pp Task.all

#Update due date for specific task
task_to_update = Task.where(taskname: 'Install SQL Server 2017 on Windows').where(user: 'Andrea').first
puts "Updating the following task:"
pp task_to_update
task_to_update.update_attribute(:duedate, '2017-07-31')
puts "Due date changed:"
pp task_to_update

#Destroy all tasks for specific user
tasks_to_delete = Task.where(user: 'Meet').first
puts "Deleting all tasks for user:"
pp tasks_to_delete
tasks_to_delete.destroy!

#Read all tasks
puts "Printing all tasks:"
pp Task.all

ActiveRecord::Base.connection.close