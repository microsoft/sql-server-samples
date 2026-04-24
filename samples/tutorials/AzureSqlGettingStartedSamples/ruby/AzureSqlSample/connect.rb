    require 'tiny_tds'
@client = TinyTds::Client.new username: 'your_user@your_server', password: 'your_password',
    dataserver: 'your_server.database.windows.net', database: 'your_database', azure: true

puts 'Connecting to Azure SQL'

if @client.active? == true then puts 'Done' end

@client.close