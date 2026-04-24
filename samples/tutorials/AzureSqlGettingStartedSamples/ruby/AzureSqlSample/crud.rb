require 'tiny_tds'
@client = TinyTds::Client.new username: 'sa', password: 'your_password',
    host: 'localhost', port: 1433
puts 'Connecting to SQL Server'

if @client.active? == true then puts 'Done' end

def execute(sql)
    result = @client.execute(sql)
    result.each
    if result.affected_rows > 0 then puts "#{result.affected_rows} row(s) affected" end
end

# Create database SampleDB
puts "Dropping and creating database 'SampleDB'"
execute("DROP DATABASE IF EXISTS [SampleDB]; CREATE DATABASE [SampleDB];")

# Create sample table with data
puts "Creating sample table with data"
execute("USE SampleDB; CREATE TABLE Employees (Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  Name NVARCHAR(50), Location NVARCHAR(50))
  INSERT INTO Employees (Name, Location) VALUES (N'Jared', N'Australia'),
  (N'Nikita', N'India'), (N'Tom', N'Germany')")

# Insert new employee
puts "Inserting new employee Jake into Employees table"
execute("INSERT INTO Employees (Name, Location) VALUES (N'Jake', N'United States')")

# Update location for employee
puts "Updating Location for Nikita"
execute("UPDATE Employees SET Location = N'United States' WHERE NAME = N'Nikita'")

# Delete employee
puts "Deleting employee Jared"
execute("DELETE FROM Employees WHERE NAME = N'Jared'")

# Read all employees
puts "Reading data from table"
@client.execute("SELECT * FROM Employees").each do |row|
    puts row
end

puts "All done."

@client.close