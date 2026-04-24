#Using the pymssql driver
import pymssql

#Connect to your database.
#Replace server name, username, and password with your credentials
#Code is dependent on AdventureWorks database
conn = pymssql.connect(server='yourserver', user='yourusername@yourserver',
	password='yourpassword', database='yourdatabase')
cursor = conn.cursor()

#SELECT
#Execute a simple select statement.
cursor.execute('SELECT TOP 10 Title, FirstName, LastName from SalesLT.Customer;')
row = cursor.fetchone()

#Print results from select statement.
while row:
    print str(row[0]) + " " + str(row[1]) + " " + str(row[2])
    row = cursor.fetchone()

#INSERT
#Execute an insert statement
cursor.execute("INSERT SalesLT.Product (Name, ProductNumber, Color, StandardCost, ListPrice, SellStartDate) OUTPUT INSERTED.ProductID VALUES ('Bike', 'B1', 'Blue', 50, 120, CURRENT_TIMESTAMP)")
row = cursor.fetchone()

#Print the ID of the inserted row.
while row:
    print "Inserted Product ID : " +str(row[0])
    row = cursor.fetchone()



