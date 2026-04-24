use HeroDb;
go

drop table if exists Hero;
drop procedure if exists InsertHero;
go

create table Hero (
	id int primary key identity,
	name nvarchar(40)
);
go

declare @heroes nvarchar(4000) =
N'[
    { "name": "Mr. Nice" },
    { "name": "Narco" },
    { "name": "Bombasto" },
    { "name": "Celeritas" },
    { "name": "Magneta" },
    { "name": "RubberMan" },
    { "name": "Dynama" },
    { "name": "Dr IQ" },
    { "name": "Magma" },
    { "name": "Tornado" }
]';

insert into Hero(name)
select name
from openjson(@heroes) with (name nvarchar(40));
GO

CREATE PROCEDURE dbo.InsertHero(@hero nvarchar(4000))
AS BEGIN

	insert into Hero(name)
	select name
	from openjson(@hero) with (name nvarchar(40));

	-- put generated id in @hero JSON object and return it back to client.
	select JSON_MODIFY(@hero, '$.id', @@IDENTITY)

END