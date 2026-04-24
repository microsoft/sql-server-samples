declare @json nvarchar(max) =
N'{
	"Name": "Vlade",
	"Surname": "Divac",
	"Born": { "DoB":"1968-03-02","Town":"Prijepolje", "Country": "Serbia"},
	"NBA Stat": { "pts":13398, "ppg": 11.8, "rebounds":	9326, "rpg": 8.2, "blocks":	1631, "bpg": 1.4},
	"Teams": ["Los Angeles Lakers","Sacramento Kings","Partizan"],
	"Career": [
		{"team":"Sloga", "period":{"start":1983, "end":1986}},
		{"team":"Partizan", "period":{"start":1986, "end":1989}},
		{"team":"Los Angeles Lakers","gp":540, "gs":450, "period":{"start":1989, "end":1996}},
		{"team":"Charlotte Hornets","gp":145, "gs":121,"period":{"start":1996, "end":1998}},
		{"team":"Sacramento Kings","gp":454, "gs":453,"period":{"start":1998, "end":2004}},
		{"team":"Los Angeles Lakers", "gp":15, "gs":0,"period":{"start":2004, "end":2005}}],
	"Bio":"Vlade Divac (Serbian Cyrillic: Владе Дивац) (born February 3, 1968) is a retired Serbian professional basketball player and is currently the vice president of basketball operations and general manager of the Sacramento Kings.[1]. Divac spent most of his career in the National Basketball Association (NBA). At 7 ft 1 in, he played center and was known for his passing skills. Divac was among the first group of European basketball players to transfer to the NBA in the late 1980s and was named one of the 50 Greatest Euroleague Contributors.[2] Divac is one of seven players in NBA history to record 13,000 points, 9,000 rebounds, 3,000 assists and 1,500 blocked shots, along with Kareem Abdul-Jabbar, Tim Duncan, Shaquille O''Neal, Kevin Garnett, Pau Gasol and Hakeem Olajuwon.[3][n 1] Divac was also the first player born and trained outside the United States to play in over 1,000 games in the NBA. On August 20, 2010, Divac was inducted into the FIBA Hall of Fame in recognition of his play in international competition.[4] Aside from being noticed for his basketball abilities, Divac is also known as a humanitarian, helping children in his native country of Serbia, and in Africa.[5] In October 2008 Divac was appointed a government adviser in Serbia for humanitarian issues.[6] In February 2009 he was elected President of the Serbian Olympic Committee for a 4-year term.[7] and re-elected in November 2012,[8] Divac received an honor from the World Sports Humanitarian Hall of Fame.[9], In summer 1986, at 18, right after signing for KK Partizan, Divac debuted for the senior Yugoslavia national basketball team at the 1986 FIBA World Championship in Madrid, on invitation by the head coach Krešimir Ćosić. However, the excellent rookie''s performance was spoiled by the event in the semi-finals against Soviet Union. Forty-five seconds before the end, Yugoslavia had a comfortable lead of 9 points, but Soviets scored two three-pointers within a few seconds and cut the difference to 3 points. Yugoslavia tried to hold the ball for the remaining time, opting to continue the play with throw-ins instead of free throws following fouls, but with only 14 seconds left, Divac committed a double dribble, the Soviets were awarded the ball, and tied the score with another three-pointer. In the overtime, the Soviets easily prevailed against the shocked Yugoslavs, who had to be content with the bronze.[10] The next year, Divac participated in the team that took the gold at the FIBA Junior World Championship (since split into separate under-19 and under-21 events) in Bormio, Italy. That event launched the young generation of Yugoslavian basketballers, also featuring stars like Rađa and Kukoč, regarded as likely the best in history. Before the breakup of Yugoslavia, they would also take the titles at EuroBasket 1989 and the 1990 FIBA World Championship in Argentina,[10] where they were led by Dražen Petrović,[24] as well as the EuroBasket 1991 title, with Aleksandar Đorđević at point guard.[25], Drafted into the NBA in 1989 by the Los Angeles Lakers. He was also one of the first European players to have an impact in the league. Under the mentorship of Kareem Abdul-Jabbar and Magic Johnson, he improved his play and adapted to the American style of the game. Though he spoke no English, he quickly became popular among his teammates and the public for his charm and joviality. In the 1989–90 season, he was selected into the NBA All-Rookie Team.[10] Divac earned a reputation for flopping, or deceiving the officials into calling a foul on the other team by purposely falling to the floor upon contact with an opposing player.[12] Veteran NBA forward P. J. Brown claimed that Divac might have been the best of all time at flopping.[13] Divac freely admitted doing so, adding that he usually did it when he felt like the officials had missed some calls and owed him.[14] Ian Thomsen, a Sports Illustrated columnist, grouped Divac with fellow international players Anderson Varejão and Manu Ginóbili as the players who \"made [flopping] famous\", exaggerating contact on the court in a manner analogous to diving in FIFA games.[15]"
 }'

----> Check is @json properly formatted.
--SELECT ISJSON(@json)


----> Get a value from "Name" key
--SELECT JSON_VALUE(@json, '$.Name')


----> Get a value from "Born.Dob" path
-- SELECT JSON_VALUE(@json, '$.Born.DoB')


----> Get a value from "Career[2].period.start" path
--SELECT JSON_VALUE(@json, '$.Career[2].period.start')


----> Use "" if your key has non-alphanumeric characters.
--SELECT JSON_VALUE(@json, '$."NBA Stat".rebounds')


----> JSON path is case sensitive. The following query will return NULL:
--SELECT JSON_VALUE(@json, '$.name')


----> It will fail because $.Bio is bigger than 8K.
----  Without strict it would return null.
--SELECT JSON_VALUE(@json, 'strict $.Bio')


----> JSON_VALUE returns NULL if object is referenced
--SELECT JSON_VALUE(@json, '$.Born')


----> JSON_QUERY returns content of the object
--SELECT JSON_QUERY(@json, '$.Born')


----> JSON_QUERY will fail because $.Name is not an object.
--SELECT JSON_QUERY(@json, 'strict $.Name')


----> JSON_MODIFY updates JSON text with a new value on a specified path.
-- SELECT JSON_MODIFY(@json, '$.Bio', 'Vlade Divac is a retired professional NBA player...')


----> JSON_MODIFY may even append elements in an array.
-- SELECT JSON_MODIFY(@json, 'append $.Teams', 'Charlotte Hornets')



----> Problem: this function will set text
---- "{\"DoB\":\"02/03/1968\",\"Town\":\"Prijepolje\"}"
---- instead of the object {"DoB":"02/03/1968","Town":"Prijepolje"}
-- SELECT JSON_MODIFY(@json, '$.Born', '{"DoB":"02/03/1968","Town":"Prijepolje"}')


----> Solution: use JSON_QUERY to "cast" JSON text to JSON
----  Input text will not be escaped.
-- SELECT JSON_MODIFY(@json, '$.Born', JSON_QUERY('{"DoB":"02/03/1968","Town":"Prijepolje"}'))



----> Get all fields from a JSON:
--SELECT * FROM OPENJSON(@json)



----> Get all Fields from an object in the specified path:
--SELECT * FROM OPENJSON(@json, '$.Born')


----> Get all elements from an array on the specified path:
--SELECT * FROM OPENJSON(@json, '$.Teams')



--SELECT value FROM OPENJSON(@json) WHERE [key] = 'Bio'



-- SELECT Bio FROM OPENJSON(@json) WITH (Bio nvarchar(MAX))



--SELECT * FROM OPENJSON(@json, '$.Born')
--			WITH (DoB datetime2, Town nvarchar(50), Country nvarchar(50))



--SELECT * FROM OPENJSON(@json, '$.Career')
--			WITH (team nvarchar(50), gp int, gs int)


----> Paths in column definitions enable you to parse nested JSON.
--SELECT *
--FROM OPENJSON(@json, '$.Career')
--			WITH (team nvarchar(50), gp int, gs int,
--					StartYear int '$.period.start',
--					EndYear int '$.period.end')


----> AS JSON option returns JSON nested object.
--SELECT *
--FROM OPENJSON(@json, '$.Career')
--		WITH (team nvarchar(50), gp int, gs int,
--				period nvarchar(max) AS JSON)

----> Use CROSS APPLY OPENJSON to parse nested period array on the 2nd level.
--SELECT team, gp, gs, start, [end]
--FROM OPENJSON(@json, '$.Career')
--	WITH (team nvarchar(50), gp int, gs int,
--				period nvarchar(max) AS JSON)
--	CROSS APPLY OPENJSON (period)
--				WITH (start int, [end] int)




--select 1 as x, 2 as y, 3 as z, null as nothing
--for json path;




--select 1 as "point.x", 2 as "point.y", 3 as z
--for json path



--with src(x,y) as (select 1 as x, 2 as y union select 3 as x, 4 as y)
--select * from src
--for json path;





--select 1 as x, 2 as y, 3 as z
--for json path, without_array_wrapper;





--with src(x,y) as (select 1 as x, 2 as y union select 3 as x, 4)
--select * from src
--for json path, without_array_wrapper



--select 1 as x, 2 as y, 3 as z for json path, root('object')






--select 1 as x, 2 as y, 3 as z,
--		JSON_QUERY('{"x":1,"y":2}') as json
--for json path





--select 1 as x, 2 as y, 3 as z,
--		(select 1 as x, 2 as y for json path) as json
--for json path





--select 1 as x, 2 as y, 3 as z,
--		(select 1 as x, 2 as y for json path, without_array_wrapper) as NOjson
--for json path



--select 1 as x, 2 as y, 3 as z,
--		JSON_QUERY((select 1 as x, 2 as y for json path, without_array_wrapper)) as json
--for json path