/*
CREATE DATABASE TodoDb;
USE TodoDb;
*/
DROP TABLE IF EXISTS Todo
DROP PROCEDURE IF EXISTS createTodo
DROP PROCEDURE IF EXISTS updateTodo
GO

CREATE TABLE Todo (
	id int IDENTITY PRIMARY KEY,
	title nvarchar(30) NOT NULL,
	description nvarchar(4000),
	completed bit,
	dueDate datetime2 default (dateadd(day, 3, getdate()))
)
GO

INSERT INTO Todo (title, description, completed, dueDate)
VALUES
('Install SQL Server 2016','Install RTM version of SQL Server 2016', 0, '2017-03-08'),
('Get new samples','Go to github and download new samples', 0, '2016-03-09'),
('Try new samples','Install new Management Studio to try samples', 0, '2016-03-12')

GO

create procedure dbo.createTodo(@todo nvarchar(max))
as begin
	insert into Todo
	select *
	from OPENJSON(@todo)
			WITH (	title nvarchar(30), description nvarchar(4000),
					completed bit, dueDate datetime2)
end
GO

create procedure updateTodo(@id int, @todo nvarchar(max))
as begin
	update Todo
    set title = json.title, description = json.description,
        completed = json.completed, dueDate = json.dueDate
    from OPENJSON( @todo )
			WITH(   title nvarchar(30), description nvarchar(4000),
					completed bit, dueDate datetime2) AS json
    where id = @id
end
go

select * from todo for json path