DROP TABLE IF EXISTS dbo.People
GO
CREATE TABLE dbo.People(
	id int primary key identity,
	name nvarchar(50),
	surname nvarchar(50),
	address nvarchar(200),
	town nvarchar(50)
)
GO

alter database current set compatibility_level = 130;
go

--select name, surname, address, town from dbo.People for json path
declare @people nvarchar(max) =
N'[{"name":"俊","surname":"渡邉󠄐","address":"神奈川県藤沢市辻堂１－１－４１","town":"辻堂"},{"name":"龍󠄄之介","surname":"渡邉󠄑","address":"神奈川県藤沢市辻󠄀堂１－５０３","town":"辻󠄀堂"},{"name":"博美","surname":"渡邉󠄒","address":"兵庫県芦屋市精道町7番6号","town":"芦屋"},{"name":"浩一","surname":"田辺","address":"東京都港区港南２－１６－３","town":"港南"},{"name":"洋子","surname":"田辺󠄁","address":"鹿児島県薩摩川内市神田町3番22号","town":"薩摩"},{"name":"大輔","surname":"田辺󠄂","address":"愛知県名古屋市熱田区川並町２－１","town":"川並"},{"name":"由紀","surname":"斎藤","address":"滋賀県東近江市五個荘川並󠄂町１－１","town":"川並󠄂"},{"name":"俊󠄁","surname":"齋󠄂藤","address":"東京都葛󠄀飾区小岩１－１－１","town":"葛󠄀飾"},{"name":"龍一","surname":"齋󠄃藤","address":"岡山県備前市東片上126番地 ","town":"芦󠄆別市"},{"name":"花子","surname":"龍地","address":"茨城県水戸市備󠄁前町816-2","town":"芦󠄂別市"},{"name":"次郎","surname":"龍󠄃地","address":"奈良県天理市備󠄂前町2-2-2","town":"芦別市"},{"name":"龍󠄅二","surname":"伴","address":"兵庫県芦󠄀屋市精道町7番6号","town":"芦󠄂屋"}]';

insert into people (name, surname, address, town)
select name, surname, address, town
from openjson(@people)
with (name nvarchar(50),surname nvarchar(50),address nvarchar(200),town nvarchar(50))