require 'tiny_tds'
@client = TinyTds::Client.new username: 'your_user@your_server', password: 'your_password',
    dataserver: 'your_server.database.windows.net', database: 'your_database', azure: true, timeout: 600


# Calculate time difference in milliseconds
def time_diff_milli(start, finish)
   ((finish - start) * 1000).floor
end

def execute(sql)
    @client.execute(sql).do
    true
end

# Ensure the table doesn't already exist.
puts "Drop the table if it exists"
execute("Drop table if exists Table_with_3M_rows")

# Insert 3 million rows into the table 'Table_with_3M_rows'
puts "Inserting 3 million rows into table 'Table_with_3M_rows'. This takes ~1 minute, please wait."
execute("WITH a AS (SELECT * FROM (VALUES(1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS a(a))
    SELECT TOP(3000000)
    ROW_NUMBER() OVER (ORDER BY a.a) AS OrderItemId
    ,a.a + b.a + c.a + d.a + e.a + f.a + g.a + h.a AS OrderId
    ,a.a * 10 AS Price
    ,CONCAT(a.a, N' ', b.a, N' ', c.a, N' ', d.a, N' ', e.a, N' ', f.a, N' ', g.a, N' ', h.a) AS ProductName
    INTO Table_with_3M_rows
    FROM a, a AS b, a AS c, a AS d, a AS e, a AS f, a AS g, a AS h;")

# Execute query without columnstore index
t1 = Time.now
execute("SELECT SUM(Price) as sum FROM Table_with_3M_rows")
t2 = Time.now
elapsedTimeWithoutIndex = time_diff_milli t1, t2
puts "Query time without columnstore index: #{elapsedTimeWithoutIndex}ms"

# Create columnnstore index on table 'Table_with_3M_rows'
puts("Adding a columnstore index to table 'Table_with_3M_rows'")
execute("CREATE CLUSTERED COLUMNSTORE INDEX columnstoreindex ON Table_with_3M_rows;")

# Execute the same query with columnstore index
t3 = Time.now
execute("SELECT SUM(Price) as sum FROM Table_with_3M_rows")
t4 = Time.now
elapsedTimeWithIndex = time_diff_milli t3, t4
puts "Query time WITH columnstore index: #{elapsedTimeWithIndex}ms"

# Calculate performance improvement with columnstore index
perf_improvement = (elapsedTimeWithoutIndex / elapsedTimeWithIndex).floor
puts "Performance improvement with columnstore index: #{perf_improvement}x!"

@client.close