USE master
GO
DROP DATABASE IF EXISTS Blogging
GO
CREATE DATABASE Blogging
GO
USE Blogging
GO
CREATE TABLE Blogs (
    BlogId int PRIMARY KEY IDENTITY,
    Url nvarchar(4000) NOT NULL,
	Tags nvarchar(4000),
	Owner nvarchar(4000)
);
GO

CREATE TABLE Posts (
    PostId int PRIMARY KEY IDENTITY,
    BlogId int NOT NULL FOREIGN KEY (BlogId) REFERENCES Blogs (BlogId) ON DELETE CASCADE,
    Content nvarchar(max),
    Title nvarchar(4000),
	Tags nvarchar(4000)
);
GO
DELETE Blogs;
GO
INSERT INTO Blogs (Url, Tags, Owner) VALUES
('http://blogs.msdn.com/dotnet', '[".Net", "Core", "C#"]','{"Name":"John","Surname":"Doe","Email":"john.doe@contoso.com"}'),
('http://blogs.msdn.com/webdev', '[".Net", "Core", "ASP.NET"]','{"Name":"Jane","Surname":"Doe","Email":"jane@contoso.com"}'),
('http://blogs.msdn.com/visualstudio', '[".Net", "VS"]','{"Name":"Jack","Surname":"Doe","Email":"jack.doe@contoso.com"}'),
('https://blogs.msdn.microsoft.com/sqlserverstorageengine/', '["SQL Server"]','{"Name":"Mike","Surname":"Doe","Email":"mike.doe@contoso.com"}')

-- Add indexing on Name property in JSON column:
ALTER TABLE Blogs
	ADD OwnerName AS JSON_VALUE(Owner, '$.Name');

CREATE INDEX ix_OwnerName
	ON Blogs(OwnerName);


