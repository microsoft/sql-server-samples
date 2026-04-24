DELETE FROM [dbo].[Employees];
DELETE FROM [dbo].[AspNetRoles];
DELETE FROM [dbo].[AspNetUsers];
DELETE FROM [dbo].[AspNetUserRoles];
GO

DECLARE @SSN1 char(11) = '795-73-9833'; DECLARE @Salary1 Money = 61692.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN1, 'Catherine', 'Abel', @Salary1);
DECLARE @SSN2 char(11) = '990-00-6818'; DECLARE @Salary2 Money = 990.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN2, 'Kim', 'Abercrombie', @Salary2);
DECLARE @SSN3 char(11) = '009-37-3952'; DECLARE @Salary3 Money = 5684.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN3, 'Frances', 'Adams', @Salary3);
DECLARE @SSN4 char(11) = '708-44-3627'; DECLARE @Salary4 Money = 55415.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN4, 'Jay', 'Adams', @Salary4);
DECLARE @SSN5 char(11) = '447-62-6279'; DECLARE @Salary5 Money = 49744.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN5, 'Robert', 'Ahlering', @Salary5);
DECLARE @SSN6 char(11) = '872-78-4732'; DECLARE @Salary6 Money = 38584.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN6, 'Stanley', 'Alan', @Salary6);
DECLARE @SSN7 char(11) = '898-79-8701'; DECLARE @Salary7 Money = 11918.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN7, 'Paul', 'Alcorn', @Salary7);
DECLARE @SSN8 char(11) = '561-88-3757'; DECLARE @Salary8 Money = 17349.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN8, 'Mary', 'Alexander', @Salary8);
DECLARE @SSN9 char(11) = '904-55-0991'; DECLARE @Salary9 Money = 70796.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN9, 'Michelle', 'Alexander', @Salary9);
DECLARE @SSN10 char(11) = '293-95-6617'; DECLARE @Salary10 Money = 96956.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN10, 'Marvin', 'Allen', @Salary10);
DECLARE @SSN11 char(11) = '260-99-4784'; DECLARE @Salary11 Money = 18386.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN11, 'Oscar', 'Alpuerto', @Salary11);
DECLARE @SSN12 char(11) = '605-29-1370'; DECLARE @Salary12 Money = 72548.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN12, 'Ramona', 'Antrim', @Salary12);
DECLARE @SSN13 char(11) = '731-35-9387'; DECLARE @Salary13 Money = 72180.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN13, 'Thomas', 'Armstrong', @Salary13);
DECLARE @SSN14 char(11) = '854-76-1401'; DECLARE @Salary14 Money = 79054.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN14, 'John', 'Arthur', @Salary14);
DECLARE @SSN15 char(11) = '775-20-2697'; DECLARE @Salary15 Money = 6011.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN15, 'Chris', 'Ashton', @Salary15);
DECLARE @SSN16 char(11) = '117-79-5230'; DECLARE @Salary16 Money = 87089.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN16, 'Teresa', 'Atkinson', @Salary16);
DECLARE @SSN17 char(11) = '607-41-3750'; DECLARE @Salary17 Money = 72344.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN17, 'Stephen', 'Ayers', @Salary17);
DECLARE @SSN18 char(11) = '412-66-3694'; DECLARE @Salary18 Money = 33950.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN18, 'James', 'Bailey', @Salary18);
DECLARE @SSN19 char(11) = '775-63-2547'; DECLARE @Salary19 Money = 89945.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN19, 'Douglas', 'Baldwin', @Salary19);
DECLARE @SSN20 char(11) = '779-52-1722'; DECLARE @Salary20 Money = 73236.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN20, 'Wayne', 'Banack', @Salary20);
DECLARE @SSN21 char(11) = '647-03-0271'; DECLARE @Salary21 Money = 23861.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN21, 'Robert', 'Barker', @Salary21);
DECLARE @SSN22 char(11) = '353-98-6954'; DECLARE @Salary22 Money = 75812.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN22, 'John', 'Beaver', @Salary22);
DECLARE @SSN23 char(11) = '817-89-8819'; DECLARE @Salary23 Money = 19047.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN23, 'John', 'Beaver', @Salary23);
DECLARE @SSN24 char(11) = '611-82-6762'; DECLARE @Salary24 Money = 59478.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN24, 'Edna', 'Benson', @Salary24);
DECLARE @SSN25 char(11) = '665-55-5653'; DECLARE @Salary25 Money = 98459.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN25, 'Payton', 'Benson', @Salary25);
DECLARE @SSN26 char(11) = '947-37-8651'; DECLARE @Salary26 Money = 78183.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN26, 'Robert', 'Bernacchi', @Salary26);
DECLARE @SSN27 char(11) = '071-31-7824'; DECLARE @Salary27 Money = 79399.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN27, 'Robert', 'Bernacchi', @Salary27);
DECLARE @SSN28 char(11) = '610-55-3726'; DECLARE @Salary28 Money = 20209.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN28, 'Matthias', 'Berndt', @Salary28);
DECLARE @SSN29 char(11) = '590-27-0856'; DECLARE @Salary29 Money = 24730.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN29, 'Jimmy', 'Bischoff', @Salary29);
DECLARE @SSN30 char(11) = '008-73-9012'; DECLARE @Salary30 Money = 60057.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN30, 'Mae', 'Black', @Salary30);
DECLARE @SSN31 char(11) = '137-23-1723'; DECLARE @Salary31 Money = 65301.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN31, 'Donald', 'Blanton', @Salary31);
DECLARE @SSN32 char(11) = '969-53-6095'; DECLARE @Salary32 Money = 5635.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN32, 'Michael', 'Blythe', @Salary32);
DECLARE @SSN33 char(11) = '222-42-8458'; DECLARE @Salary33 Money = 41020.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN33, 'Gabriel', 'Bockenkamp', @Salary33);
DECLARE @SSN34 char(11) = '163-08-2988'; DECLARE @Salary34 Money = 85014.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN34, 'Luis', 'Bonifaz', @Salary34);
DECLARE @SSN35 char(11) = '898-11-0280'; DECLARE @Salary35 Money = 49351.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN35, 'Cory', 'Booth', @Salary35);
DECLARE @SSN36 char(11) = '432-52-2738'; DECLARE @Salary36 Money = 24063.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN36, 'Randall', 'Boseman', @Salary36);
DECLARE @SSN37 char(11) = '018-29-9539'; DECLARE @Salary37 Money = 91513.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN37, 'Cornelius', 'Brandon', @Salary37);
DECLARE @SSN38 char(11) = '472-36-9060'; DECLARE @Salary38 Money = 26084.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN38, 'Richard', 'Bready', @Salary38);
DECLARE @SSN39 char(11) = '566-87-9214'; DECLARE @Salary39 Money = 95506.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN39, 'Ted', 'Bremer', @Salary39);
DECLARE @SSN40 char(11) = '771-34-9714'; DECLARE @Salary40 Money = 35682.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN40, 'Alan', 'Brewer', @Salary40);
DECLARE @SSN41 char(11) = '413-73-7072'; DECLARE @Salary41 Money = 5198.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN41, 'Walter', 'Brian', @Salary41);
DECLARE @SSN42 char(11) = '497-65-6363'; DECLARE @Salary42 Money = 24216.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN42, 'Christopher', 'Bright', @Salary42);
DECLARE @SSN43 char(11) = '450-26-2195'; DECLARE @Salary43 Money = 55078.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN43, 'Willie', 'Brooks', @Salary43);
DECLARE @SSN44 char(11) = '052-78-7929'; DECLARE @Salary44 Money = 17396.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN44, 'Jo', 'Brown', @Salary44);
DECLARE @SSN45 char(11) = '087-92-6356'; DECLARE @Salary45 Money = 99872.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN45, 'Robert', 'Brown', @Salary45);
DECLARE @SSN46 char(11) = '048-71-8953'; DECLARE @Salary46 Money = 88633.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN46, 'Steven', 'Brown', @Salary46);
DECLARE @SSN47 char(11) = '488-68-6075'; DECLARE @Salary47 Money = 59229.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN47, 'Mary', 'Browning', @Salary47);
DECLARE @SSN48 char(11) = '819-63-3780'; DECLARE @Salary48 Money = 30996.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN48, 'Michael', 'Brundage', @Salary48);
DECLARE @SSN49 char(11) = '599-61-7739'; DECLARE @Salary49 Money = 35872.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN49, 'Shirley', 'Bruner', @Salary49);
DECLARE @SSN50 char(11) = '772-36-0661'; DECLARE @Salary50 Money = 84642.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN50, 'June', 'Brunner', @Salary50);
DECLARE @SSN51 char(11) = '990-78-3760'; DECLARE @Salary51 Money = 76800.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN51, 'Megan', 'Burke', @Salary51);
DECLARE @SSN52 char(11) = '103-38-5903'; DECLARE @Salary52 Money = 93306.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN52, 'Karren', 'Burkhardt', @Salary52);
DECLARE @SSN53 char(11) = '146-43-8832'; DECLARE @Salary53 Money = 56479.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN53, 'Linda', 'Burnett', @Salary53);
DECLARE @SSN54 char(11) = '448-72-5948'; DECLARE @Salary54 Money = 7997.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN54, 'Jared', 'Bustamante', @Salary54);
DECLARE @SSN55 char(11) = '254-13-4819'; DECLARE @Salary55 Money = 28720.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN55, 'Barbara', 'Calone', @Salary55);
DECLARE @SSN56 char(11) = '666-45-9926'; DECLARE @Salary56 Money = 11870.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN56, 'Lindsey', 'Camacho', @Salary56);
DECLARE @SSN57 char(11) = '260-46-2402'; DECLARE @Salary57 Money = 87501.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN57, 'Frank', 'Campbell', @Salary57);
DECLARE @SSN58 char(11) = '189-92-4702'; DECLARE @Salary58 Money = 30494.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN58, 'Henry', 'Campen', @Salary58);
DECLARE @SSN59 char(11) = '718-12-8401'; DECLARE @Salary59 Money = 2324.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN59, 'Chris', 'Cannon', @Salary59);
DECLARE @SSN60 char(11) = '918-66-9747'; DECLARE @Salary60 Money = 22620.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN60, 'Jane', 'Carmichael', @Salary60);
DECLARE @SSN61 char(11) = '806-97-1958'; DECLARE @Salary61 Money = 37601.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN61, 'Jovita', 'Carmody', @Salary61);
DECLARE @SSN62 char(11) = '482-61-8230'; DECLARE @Salary62 Money = 16904.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN62, 'Rob', 'Caron', @Salary62);
DECLARE @SSN63 char(11) = '897-39-6229'; DECLARE @Salary63 Money = 40261.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN63, 'Andy', 'Carothers', @Salary63);
DECLARE @SSN64 char(11) = '656-79-6279'; DECLARE @Salary64 Money = 78393.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN64, 'Donna', 'Carreras', @Salary64);
DECLARE @SSN65 char(11) = '745-99-0161'; DECLARE @Salary65 Money = 98109.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN65, 'Rosmarie', 'Carroll', @Salary65);
DECLARE @SSN66 char(11) = '216-16-4120'; DECLARE @Salary66 Money = 41706.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN66, 'Raul', 'Casts', @Salary66);
DECLARE @SSN67 char(11) = '102-56-5530'; DECLARE @Salary67 Money = 75290.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN67, 'Matthew', 'Cavallari', @Salary67);
DECLARE @SSN68 char(11) = '787-23-4125'; DECLARE @Salary68 Money = 75121.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN68, 'Andrew', 'Cencini', @Salary68);
DECLARE @SSN69 char(11) = '424-55-1778'; DECLARE @Salary69 Money = 25456.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN69, 'Stacey', 'Cereghino', @Salary69);
DECLARE @SSN70 char(11) = '572-19-0999'; DECLARE @Salary70 Money = 49996.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN70, 'Forrest', 'Chandler', @Salary70);
DECLARE @SSN71 char(11) = '745-81-6513'; DECLARE @Salary71 Money = 70991.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN71, 'Lee', 'Chapla', @Salary71);
DECLARE @SSN72 char(11) = '947-66-5585'; DECLARE @Salary72 Money = 72455.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN72, 'Yao-Qiang', 'Cheng', @Salary72);
DECLARE @SSN73 char(11) = '531-83-4784'; DECLARE @Salary73 Money = 13676.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN73, 'Nicky', 'Chesnut', @Salary73);
DECLARE @SSN74 char(11) = '109-99-0299'; DECLARE @Salary74 Money = 55818.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN74, 'Ruth', 'Choin', @Salary74);
DECLARE @SSN75 char(11) = '483-85-6853'; DECLARE @Salary75 Money = 71421.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN75, 'Anthony', 'Chor', @Salary75);
DECLARE @SSN76 char(11) = '567-39-1024'; DECLARE @Salary76 Money = 57284.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN76, 'Pei', 'Chow', @Salary76);
DECLARE @SSN77 char(11) = '382-49-7387'; DECLARE @Salary77 Money = 94767.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN77, 'Jill', 'Christie', @Salary77);
DECLARE @SSN78 char(11) = '336-03-8102'; DECLARE @Salary78 Money = 47963.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN78, 'Alice', 'Clark', @Salary78);
DECLARE @SSN79 char(11) = '994-22-9926'; DECLARE @Salary79 Money = 32136.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN79, 'Connie', 'Coffman', @Salary79);
DECLARE @SSN80 char(11) = '129-28-7723'; DECLARE @Salary80 Money = 82858.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN80, 'John', 'Colon', @Salary80);
DECLARE @SSN81 char(11) = '347-44-2949'; DECLARE @Salary81 Money = 1121.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN81, 'Scott', 'Colvin', @Salary81);
DECLARE @SSN82 char(11) = '706-66-0382'; DECLARE @Salary82 Money = 22281.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN82, 'Scott', 'Cooper', @Salary82);
DECLARE @SSN83 char(11) = '500-63-2220'; DECLARE @Salary83 Money = 34410.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN83, 'Eva', 'Corets', @Salary83);
DECLARE @SSN84 char(11) = '942-15-7859'; DECLARE @Salary84 Money = 43154.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN84, 'Marlin', 'Coriell', @Salary84);
DECLARE @SSN85 char(11) = '143-78-9971'; DECLARE @Salary85 Money = 66527.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN85, 'Jack', 'Creasey', @Salary85);
DECLARE @SSN86 char(11) = '372-18-7905'; DECLARE @Salary86 Money = 69903.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN86, 'Grant', 'Culbertson', @Salary86);
DECLARE @SSN87 char(11) = '153-33-1155'; DECLARE @Salary87 Money = 87717.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN87, 'Scott', 'Culp', @Salary87);
DECLARE @SSN89 char(11) = '790-69-5423'; DECLARE @Salary89 Money = 69707.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN89, 'Megan', 'Davis', @Salary89);
DECLARE @SSN90 char(11) = '105-16-8373'; DECLARE @Salary90 Money = 15198.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN90, 'Alvaro', 'De Matos Miranda Filho', @Salary90);
DECLARE @SSN91 char(11) = '989-18-3523'; DECLARE @Salary91 Money = 86115.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN91, 'Aidan', 'Delaney', @Salary91);
DECLARE @SSN92 char(11) = '771-07-7325'; DECLARE @Salary92 Money = 50994.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN92, 'Stefan', 'Delmarco', @Salary92);
DECLARE @SSN93 char(11) = '545-83-9747'; DECLARE @Salary93 Money = 97968.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN93, 'Prashanth', 'Desai', @Salary93);
DECLARE @SSN94 char(11) = '994-72-1605'; DECLARE @Salary94 Money = 76954.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN94, 'Bev', 'Desalvo', @Salary94);
DECLARE @SSN95 char(11) = '558-23-5595'; DECLARE @Salary95 Money = 4027.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN95, 'Brenda', 'Diaz', @Salary95);
DECLARE @SSN96 char(11) = '752-63-1338'; DECLARE @Salary96 Money = 12312.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN96, 'Blaine', 'Dockter', @Salary96);
DECLARE @SSN97 char(11) = '825-10-8923'; DECLARE @Salary97 Money = 82876.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN97, 'Cindy', 'Dodd', @Salary97);
DECLARE @SSN98 char(11) = '368-69-8964'; DECLARE @Salary98 Money = 97282.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN98, 'Patricia', 'Doyle', @Salary98);
DECLARE @SSN99 char(11) = '597-44-1424'; DECLARE @Salary99 Money = 20153.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN99, 'Gerald', 'Drury', @Salary99);
DECLARE @SSN100 char(11) = '957-28-1545'; DECLARE @Salary100 Money = 89903.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN100, 'Bart', 'Duncan', @Salary100);
DECLARE @SSN101 char(11) = '187-17-8616'; DECLARE @Salary101 Money = 6725.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN101, 'Maciej', 'Dusza', @Salary101);
DECLARE @SSN102 char(11) = '194-76-9481'; DECLARE @Salary102 Money = 49287.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN102, 'Carol', 'Elliott', @Salary102);
DECLARE @SSN103 char(11) = '679-79-8165'; DECLARE @Salary103 Money = 94194.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN103, 'Shannon', 'Elliott', @Salary103);
DECLARE @SSN104 char(11) = '367-73-8845'; DECLARE @Salary104 Money = 65560.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN104, 'John', 'Emory', @Salary104);
DECLARE @SSN105 char(11) = '814-03-3691'; DECLARE @Salary105 Money = 99845.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN105, 'Gail', 'Erickson', @Salary105);
DECLARE @SSN106 char(11) = '214-28-9968'; DECLARE @Salary106 Money = 95242.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN106, 'Mark', 'Erickson', @Salary106);
DECLARE @SSN107 char(11) = '913-55-6645'; DECLARE @Salary107 Money = 48046.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN107, 'Ann', 'Evans', @Salary107);
DECLARE @SSN108 char(11) = '763-33-5650'; DECLARE @Salary108 Money = 59254.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN108, 'John', 'Evans', @Salary108);
DECLARE @SSN109 char(11) = '658-41-8532'; DECLARE @Salary109 Money = 35364.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN109, 'Twanna', 'Evans', @Salary109);
DECLARE @SSN110 char(11) = '943-41-6011'; DECLARE @Salary110 Money = 76201.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN110, 'Carolyn', 'Farino', @Salary110);
DECLARE @SSN111 char(11) = '691-30-8623'; DECLARE @Salary111 Money = 39600.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN111, 'Geri', 'Farrell', @Salary111);
DECLARE @SSN112 char(11) = '361-08-3217'; DECLARE @Salary112 Money = 3704.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN112, 'Fran�ois', 'Ferrier', @Salary112);
DECLARE @SSN113 char(11) = '827-51-1487'; DECLARE @Salary113 Money = 78467.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN113, 'Kathie', 'Flood', @Salary113);
DECLARE @SSN114 char(11) = '483-93-0057'; DECLARE @Salary114 Money = 77552.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN114, 'John', 'Ford', @Salary114);
DECLARE @SSN115 char(11) = '738-37-1607'; DECLARE @Salary115 Money = 34381.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN115, 'Garth', 'Fort', @Salary115);
DECLARE @SSN116 char(11) = '822-59-9384'; DECLARE @Salary116 Money = 32679.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN116, 'Dorothy', 'Fox', @Salary116);
DECLARE @SSN117 char(11) = '309-79-2521'; DECLARE @Salary117 Money = 52898.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN117, 'Mihail', 'Frintu', @Salary117);
DECLARE @SSN118 char(11) = '814-32-0421'; DECLARE @Salary118 Money = 1320.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN118, 'Paul', 'Fulton', @Salary118);
DECLARE @SSN119 char(11) = '076-35-8143'; DECLARE @Salary119 Money = 24061.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN119, 'Michael', 'Galos', @Salary119);
DECLARE @SSN120 char(11) = '620-03-4764'; DECLARE @Salary120 Money = 70002.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN120, 'Jon', 'Ganio', @Salary120);
DECLARE @SSN121 char(11) = '769-76-3600'; DECLARE @Salary121 Money = 89479.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN121, 'Dominic', 'Gash', @Salary121);
DECLARE @SSN122 char(11) = '160-92-3129'; DECLARE @Salary122 Money = 49178.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN122, 'Janet', 'Gates', @Salary122);
DECLARE @SSN123 char(11) = '318-00-6667'; DECLARE @Salary123 Money = 68327.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN123, 'Janet', 'Gates', @Salary123);
DECLARE @SSN124 char(11) = '982-77-3975'; DECLARE @Salary124 Money = 53281.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN124, 'Orlando', 'Gee', @Salary124);
DECLARE @SSN125 char(11) = '328-68-1544'; DECLARE @Salary125 Money = 13353.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN125, 'Darren', 'Gehring', @Salary125);
DECLARE @SSN126 char(11) = '053-51-9173'; DECLARE @Salary126 Money = 91180.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN126, 'Jim', 'Geist', @Salary126);
DECLARE @SSN127 char(11) = '840-05-6646'; DECLARE @Salary127 Money = 3780.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN127, 'Guy', 'Gilbert', @Salary127);
DECLARE @SSN128 char(11) = '446-11-2924'; DECLARE @Salary128 Money = 89588.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN128, 'Janet', 'Gilliat', @Salary128);
DECLARE @SSN129 char(11) = '273-16-2522'; DECLARE @Salary129 Money = 53352.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN129, 'Mary', 'Gimmi', @Salary129);
DECLARE @SSN130 char(11) = '003-23-9305'; DECLARE @Salary130 Money = 49086.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN130, 'Jeanie', 'Glenn', @Salary130);
DECLARE @SSN131 char(11) = '878-44-1968'; DECLARE @Salary131 Money = 2744.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN131, 'Scott', 'Gode', @Salary131);
DECLARE @SSN132 char(11) = '910-05-4138'; DECLARE @Salary132 Money = 89053.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN132, 'Mete', 'Goktepe', @Salary132);
DECLARE @SSN133 char(11) = '912-33-3174'; DECLARE @Salary133 Money = 56550.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN133, 'Abigail', 'Gonzalez', @Salary133);
DECLARE @SSN134 char(11) = '058-26-3234'; DECLARE @Salary134 Money = 41144.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN134, 'Michael', 'Graff', @Salary134);
DECLARE @SSN135 char(11) = '687-28-3396'; DECLARE @Salary135 Money = 22262.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN135, 'Douglas', 'Groncki', @Salary135);
DECLARE @SSN136 char(11) = '496-75-4904'; DECLARE @Salary136 Money = 35712.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN136, 'Brian', 'Groth', @Salary136);
DECLARE @SSN137 char(11) = '071-00-8057'; DECLARE @Salary137 Money = 48197.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN137, 'Erin', 'Hagens', @Salary137);
DECLARE @SSN138 char(11) = '288-05-9705'; DECLARE @Salary138 Money = 6286.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN138, 'Betty', 'Haines', @Salary138);
DECLARE @SSN139 char(11) = '002-47-6040'; DECLARE @Salary139 Money = 22940.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN139, 'Jean', 'Handley', @Salary139);
DECLARE @SSN140 char(11) = '936-84-1664'; DECLARE @Salary140 Money = 80093.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN140, 'Kerim', 'Hanif', @Salary140);
DECLARE @SSN141 char(11) = '216-03-0835'; DECLARE @Salary141 Money = 10237.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN141, 'John', 'Hanson', @Salary141);
DECLARE @SSN142 char(11) = '525-81-0810'; DECLARE @Salary142 Money = 69388.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN142, 'Lucy', 'Harrington', @Salary142);
DECLARE @SSN143 char(11) = '331-25-9319'; DECLARE @Salary143 Money = 7729.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN143, 'Keith', 'Harris', @Salary143);
DECLARE @SSN144 char(11) = '770-01-5105'; DECLARE @Salary144 Money = 67336.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN144, 'Keith', 'Harris', @Salary144);
DECLARE @SSN145 char(11) = '208-84-9956'; DECLARE @Salary145 Money = 78271.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN145, 'Roger', 'Harui', @Salary145);
DECLARE @SSN146 char(11) = '633-34-5095'; DECLARE @Salary146 Money = 62689.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN146, 'Ann', 'Hass', @Salary146);
DECLARE @SSN147 char(11) = '022-89-0200'; DECLARE @Salary147 Money = 10269.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN147, 'Valerie', 'Hendricks', @Salary147);
DECLARE @SSN148 char(11) = '912-85-8027'; DECLARE @Salary148 Money = 95103.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN148, 'Cheryl', 'Herring', @Salary148);
DECLARE @SSN149 char(11) = '307-29-4403'; DECLARE @Salary149 Money = 30421.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN149, 'Ronald', 'Heymsfield', @Salary149);
DECLARE @SSN150 char(11) = '083-68-5072'; DECLARE @Salary150 Money = 35109.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN150, 'Mike', 'Hines', @Salary150);
DECLARE @SSN151 char(11) = '239-20-6174'; DECLARE @Salary151 Money = 75140.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN151, 'Matthew', 'Hink', @Salary151);
DECLARE @SSN152 char(11) = '162-43-8489'; DECLARE @Salary152 Money = 84875.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN152, 'Bob', 'Hodges', @Salary152);
DECLARE @SSN153 char(11) = '717-37-3032'; DECLARE @Salary153 Money = 15920.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN153, 'David', 'Hodgson', @Salary153);
DECLARE @SSN154 char(11) = '280-15-5623'; DECLARE @Salary154 Money = 23680.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN154, 'Helge', 'Hoeing', @Salary154);
DECLARE @SSN155 char(11) = '353-00-9496'; DECLARE @Salary155 Money = 83632.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN155, 'Juanita', 'Holman', @Salary155);
DECLARE @SSN156 char(11) = '162-65-6542'; DECLARE @Salary156 Money = 6335.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN156, 'Peter', 'Houston', @Salary156);
DECLARE @SSN157 char(11) = '427-43-7296'; DECLARE @Salary157 Money = 90908.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN157, 'George', 'Huckaby', @Salary157);
DECLARE @SSN158 char(11) = '603-61-0319'; DECLARE @Salary158 Money = 55166.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN158, 'Joshua', 'Huff', @Salary158);
DECLARE @SSN159 char(11) = '877-01-3415'; DECLARE @Salary159 Money = 58528.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN159, 'Phyllis', 'Huntsman', @Salary159);
DECLARE @SSN160 char(11) = '391-25-8382'; DECLARE @Salary160 Money = 86920.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN160, 'Phyllis', 'Huntsman', @Salary160);
DECLARE @SSN161 char(11) = '626-56-2930'; DECLARE @Salary161 Money = 11698.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN161, 'Lawrence', 'Hurkett', @Salary161);
DECLARE @SSN162 char(11) = '731-19-3470'; DECLARE @Salary162 Money = 83202.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN162, 'Lucio', 'Iallo', @Salary162);
DECLARE @SSN163 char(11) = '171-33-3481'; DECLARE @Salary163 Money = 83990.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN163, 'Richard', 'Irwin', @Salary163);
DECLARE @SSN164 char(11) = '828-77-1376'; DECLARE @Salary164 Money = 7706.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN164, 'Erik', 'Ismert', @Salary164);
DECLARE @SSN165 char(11) = '611-48-4137'; DECLARE @Salary165 Money = 784.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN165, 'Eric', 'Jacobsen', @Salary165);
DECLARE @SSN166 char(11) = '477-14-7161'; DECLARE @Salary166 Money = 17695.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN166, 'Jodan', 'Jacobson', @Salary166);
DECLARE @SSN167 char(11) = '738-83-2602'; DECLARE @Salary167 Money = 9412.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN167, 'Sean', 'Jacobson', @Salary167);
DECLARE @SSN168 char(11) = '589-30-3617'; DECLARE @Salary168 Money = 42556.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN168, 'Joyce', 'Jarvis', @Salary168);
DECLARE @SSN169 char(11) = '538-28-5108'; DECLARE @Salary169 Money = 36190.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN169, 'Barry', 'Johnson', @Salary169);
DECLARE @SSN170 char(11) = '661-09-8547'; DECLARE @Salary170 Money = 80820.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN170, 'Barry', 'Johnson', @Salary170);
DECLARE @SSN171 char(11) = '025-55-7602'; DECLARE @Salary171 Money = 54767.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN171, 'Brian', 'Johnson', @Salary171);
DECLARE @SSN172 char(11) = '422-34-6020'; DECLARE @Salary172 Money = 26695.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN172, 'David', 'Johnson', @Salary172);
DECLARE @SSN173 char(11) = '500-92-8728'; DECLARE @Salary173 Money = 52805.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN173, 'Tom', 'Johnston', @Salary173);
DECLARE @SSN174 char(11) = '170-89-3691'; DECLARE @Salary174 Money = 68936.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN174, 'Jean', 'Jordan', @Salary174);
DECLARE @SSN175 char(11) = '108-25-0733'; DECLARE @Salary175 Money = 39764.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN175, 'Peggy', 'Justice', @Salary175);
DECLARE @SSN176 char(11) = '392-44-2253'; DECLARE @Salary176 Money = 84549.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN176, 'Sandeep', 'Kaliyath', @Salary176);
DECLARE @SSN177 char(11) = '666-10-8497'; DECLARE @Salary177 Money = 27585.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN177, 'Sandeep', 'Katyal', @Salary177);
DECLARE @SSN178 char(11) = '738-29-5963'; DECLARE @Salary178 Money = 31491.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN178, 'John', 'Kelly', @Salary178);
DECLARE @SSN179 char(11) = '253-47-6467'; DECLARE @Salary179 Money = 43239.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN179, 'Robert', 'Kelly', @Salary179);
DECLARE @SSN180 char(11) = '059-47-6363'; DECLARE @Salary180 Money = 18192.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN180, 'Kevin', 'Kennedy', @Salary180);
DECLARE @SSN181 char(11) = '382-51-9530'; DECLARE @Salary181 Money = 68959.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN181, 'Mitch', 'Kennedy', @Salary181);
DECLARE @SSN182 char(11) = '480-79-4419'; DECLARE @Salary182 Money = 66870.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN182, 'Imtiaz', 'Khan', @Salary182);
DECLARE @SSN183 char(11) = '097-39-6667'; DECLARE @Salary183 Money = 17048.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN183, 'Karan', 'Khanna', @Salary183);
DECLARE @SSN184 char(11) = '625-86-1609'; DECLARE @Salary184 Money = 97398.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN184, 'Anton', 'Kirilov', @Salary184);
DECLARE @SSN185 char(11) = '109-78-5455'; DECLARE @Salary185 Money = 22492.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN185, 'Christian', 'Kleinerman', @Salary185);
DECLARE @SSN186 char(11) = '914-28-0431'; DECLARE @Salary186 Money = 47853.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN186, 'Andrew', 'Kobylinski', @Salary186);
DECLARE @SSN187 char(11) = '428-15-1588'; DECLARE @Salary187 Money = 61377.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN187, 'Eugene', 'Kogan', @Salary187);
DECLARE @SSN188 char(11) = '612-70-0567'; DECLARE @Salary188 Money = 87060.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN188, 'Scott', 'Konersmann', @Salary188);
DECLARE @SSN189 char(11) = '025-76-2628'; DECLARE @Salary189 Money = 165.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN189, 'Joy', 'Koski', @Salary189);
DECLARE @SSN190 char(11) = '920-75-2262'; DECLARE @Salary190 Money = 12316.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN190, 'Diane', 'Krane', @Salary190);
DECLARE @SSN191 char(11) = '748-12-0172'; DECLARE @Salary191 Money = 13614.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN191, 'Kay', 'Krane', @Salary191);
DECLARE @SSN192 char(11) = '230-78-1884'; DECLARE @Salary192 Money = 98499.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN192, 'Kay', 'Krane', @Salary192);
DECLARE @SSN193 char(11) = '121-03-7961'; DECLARE @Salary193 Money = 98845.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN193, 'Margaret', 'Krupka', @Salary193);
DECLARE @SSN194 char(11) = '993-16-0574'; DECLARE @Salary194 Money = 67823.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN194, 'Peter', 'Kurniawan', @Salary194);
DECLARE @SSN195 char(11) = '560-17-8321'; DECLARE @Salary195 Money = 18840.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN195, 'Jeffrey', 'Kurtz', @Salary195);
DECLARE @SSN196 char(11) = '176-23-2126'; DECLARE @Salary196 Money = 39005.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN196, 'Eric', 'Lang', @Salary196);
DECLARE @SSN197 char(11) = '678-53-5154'; DECLARE @Salary197 Money = 71752.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN197, 'Elsa', 'Leavitt', @Salary197);
DECLARE @SSN198 char(11) = '950-17-4726'; DECLARE @Salary198 Money = 28116.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN198, 'Marjorie', 'Lee', @Salary198);
DECLARE @SSN199 char(11) = '649-28-8360'; DECLARE @Salary199 Money = 75588.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN199, 'Roger', 'Lengel', @Salary199);
DECLARE @SSN200 char(11) = '507-95-7549'; DECLARE @Salary200 Money = 71639.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN200, 'A.', 'Leonetti', @Salary200);
DECLARE @SSN201 char(11) = '442-99-4943'; DECLARE @Salary201 Money = 9089.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN201, 'Bonnie', 'Lepro', @Salary201);
DECLARE @SSN202 char(11) = '674-71-8512'; DECLARE @Salary202 Money = 93630.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN202, 'Elsie', 'Lewin', @Salary202);
DECLARE @SSN203 char(11) = '418-20-4458'; DECLARE @Salary203 Money = 74540.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN203, 'George', 'Li', @Salary203);
DECLARE @SSN204 char(11) = '986-20-3872'; DECLARE @Salary204 Money = 96968.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN204, 'Joseph', 'Lique', @Salary204);
DECLARE @SSN205 char(11) = '716-41-6291'; DECLARE @Salary205 Money = 11243.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN205, 'Paulo', 'Lisboa', @Salary205);
DECLARE @SSN206 char(11) = '475-64-2482'; DECLARE @Salary206 Money = 84392.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN206, 'Paulo', 'Lisboa', @Salary206);
DECLARE @SSN207 char(11) = '471-03-3608'; DECLARE @Salary207 Money = 57309.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN207, 'David', 'Liu', @Salary207);
DECLARE @SSN208 char(11) = '440-49-4765'; DECLARE @Salary208 Money = 34991.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN208, 'Jinghao', 'Liu', @Salary208);
DECLARE @SSN209 char(11) = '321-33-7277'; DECLARE @Salary209 Money = 20305.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN209, 'Kevin', 'Liu', @Salary209);
DECLARE @SSN210 char(11) = '113-69-0506'; DECLARE @Salary210 Money = 5368.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN210, 'Sharon', 'Looney', @Salary210);
DECLARE @SSN211 char(11) = '311-21-1551'; DECLARE @Salary211 Money = 15667.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN211, 'Judy', 'Lundahl', @Salary211);
DECLARE @SSN212 char(11) = '710-73-5330'; DECLARE @Salary212 Money = 2258.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN212, 'Denise', 'Maccietto', @Salary212);
DECLARE @SSN213 char(11) = '321-14-1319'; DECLARE @Salary213 Money = 30158.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN213, 'Scott', 'MacDonald', @Salary213);
DECLARE @SSN214 char(11) = '340-75-5874'; DECLARE @Salary214 Money = 10228.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN214, 'Kathy', 'Marcovecchio', @Salary214);
DECLARE @SSN215 char(11) = '043-85-0648'; DECLARE @Salary215 Money = 46100.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN215, 'Melissa', 'Marple', @Salary215);
DECLARE @SSN216 char(11) = '253-33-7509'; DECLARE @Salary216 Money = 46267.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN216, 'Frank', 'Mart�nez', @Salary216);
DECLARE @SSN217 char(11) = '335-68-4629'; DECLARE @Salary217 Money = 92921.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN217, 'Chris', 'Maxwell', @Salary217);
DECLARE @SSN218 char(11) = '535-30-6577'; DECLARE @Salary218 Money = 60264.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN218, 'Sandra', 'Maynard', @Salary218);
DECLARE @SSN219 char(11) = '613-34-9127'; DECLARE @Salary219 Money = 70620.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN219, 'Walter', 'Mays', @Salary219);
DECLARE @SSN220 char(11) = '754-70-9484'; DECLARE @Salary220 Money = 75175.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN220, 'Lola', 'McCarthy', @Salary220);
DECLARE @SSN221 char(11) = '758-46-9282'; DECLARE @Salary221 Money = 78021.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN221, 'Jane', 'McCarty', @Salary221);
DECLARE @SSN222 char(11) = '287-44-2853'; DECLARE @Salary222 Money = 38787.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN222, 'Yvonne', 'McKay', @Salary222);
DECLARE @SSN223 char(11) = '173-12-0893'; DECLARE @Salary223 Money = 27222.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN223, 'Nkenge', 'McLin', @Salary223);
DECLARE @SSN224 char(11) = '028-18-1290'; DECLARE @Salary224 Money = 80464.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN224, 'R. Morgan', 'Mendoza', @Salary224);
DECLARE @SSN225 char(11) = '035-47-1686'; DECLARE @Salary225 Money = 79306.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN225, 'Helen', 'Meyer', @Salary225);
DECLARE @SSN226 char(11) = '926-47-4349'; DECLARE @Salary226 Money = 64819.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN226, 'Dylan', 'Miller', @Salary226);
DECLARE @SSN227 char(11) = '947-84-3762'; DECLARE @Salary227 Money = 97091.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN227, 'Frank', 'Miller', @Salary227);
DECLARE @SSN228 char(11) = '598-00-4792'; DECLARE @Salary228 Money = 77286.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN228, 'Virginia', 'Miller', @Salary228);
DECLARE @SSN229 char(11) = '069-59-6908'; DECLARE @Salary229 Money = 57881.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN229, 'Virginia', 'Miller', @Salary229);
DECLARE @SSN230 char(11) = '864-49-8796'; DECLARE @Salary230 Money = 36848.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN230, 'Neva', 'Mitchell', @Salary230);
DECLARE @SSN231 char(11) = '484-78-0561'; DECLARE @Salary231 Money = 42987.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN231, 'Joseph', 'Mitzner', @Salary231);
DECLARE @SSN232 char(11) = '684-27-6433'; DECLARE @Salary232 Money = 46020.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN232, 'Margaret', 'Smith', @Salary232);
DECLARE @SSN233 char(11) = '521-85-5433'; DECLARE @Salary233 Money = 87969.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN233, 'Laura', 'Steele', @Salary233);
DECLARE @SSN234 char(11) = '239-08-6212'; DECLARE @Salary234 Money = 71635.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN234, 'Alan', 'Steiner', @Salary234);
DECLARE @SSN235 char(11) = '655-64-2836'; DECLARE @Salary235 Money = 60544.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN235, 'Alice', 'Steiner', @Salary235);
DECLARE @SSN236 char(11) = '850-56-7206'; DECLARE @Salary236 Money = 16798.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN236, 'Derik', 'Stenerson', @Salary236);
DECLARE @SSN237 char(11) = '077-42-9130'; DECLARE @Salary237 Money = 55399.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN237, 'Vassar', 'Stern', @Salary237);
DECLARE @SSN238 char(11) = '094-90-4314'; DECLARE @Salary238 Money = 20296.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN238, 'Wathalee', 'Steuber', @Salary238);
DECLARE @SSN239 char(11) = '409-83-6433'; DECLARE @Salary239 Money = 6631.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN239, 'Liza Marie', 'Stevens', @Salary239);
DECLARE @SSN240 char(11) = '351-34-7304'; DECLARE @Salary240 Money = 88774.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN240, 'Robert', 'Stotka', @Salary240);
DECLARE @SSN241 char(11) = '866-96-8557'; DECLARE @Salary241 Money = 19835.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN241, 'Kayla', 'Stotler', @Salary241);
DECLARE @SSN242 char(11) = '716-37-0786'; DECLARE @Salary242 Money = 38058.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN242, 'Ruth', 'Suffin', @Salary242);
DECLARE @SSN243 char(11) = '689-86-1583'; DECLARE @Salary243 Money = 98566.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN243, 'Elizabeth', 'Sullivan', @Salary243);
DECLARE @SSN244 char(11) = '622-25-6018'; DECLARE @Salary244 Money = 9242.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN244, 'Michael', 'Sullivan', @Salary244);
DECLARE @SSN245 char(11) = '137-21-0253'; DECLARE @Salary245 Money = 44883.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN245, 'Brad', 'Sutton', @Salary245);
DECLARE @SSN246 char(11) = '237-99-8262'; DECLARE @Salary246 Money = 85958.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN246, 'Abraham', 'Swearengin', @Salary246);
DECLARE @SSN247 char(11) = '518-41-6271'; DECLARE @Salary247 Money = 63622.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN247, 'Julie', 'Taft-Rider', @Salary247);
DECLARE @SSN248 char(11) = '554-31-5202'; DECLARE @Salary248 Money = 25188.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN248, 'Clarence', 'Tatman', @Salary248);
DECLARE @SSN249 char(11) = '591-44-7136'; DECLARE @Salary249 Money = 22306.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN249, 'Chad', 'Tedford', @Salary249);
DECLARE @SSN250 char(11) = '069-09-3831'; DECLARE @Salary250 Money = 44398.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN250, 'Vanessa', 'Tench', @Salary250);
DECLARE @SSN251 char(11) = '523-93-8801'; DECLARE @Salary251 Money = 89067.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN251, 'Judy', 'Thames', @Salary251);
DECLARE @SSN252 char(11) = '266-03-4963'; DECLARE @Salary252 Money = 36910.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN252, 'Daniel', 'Thompson', @Salary252);
DECLARE @SSN253 char(11) = '496-54-0726'; DECLARE @Salary253 Money = 85206.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN253, 'Donald', 'Thompson', @Salary253);
DECLARE @SSN254 char(11) = '984-43-6756'; DECLARE @Salary254 Money = 7375.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN254, 'Kendra', 'Thompson', @Salary254);
DECLARE @SSN255 char(11) = '047-31-4129'; DECLARE @Salary255 Money = 95073.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN255, 'Diane', 'Tibbott', @Salary255);
DECLARE @SSN256 char(11) = '217-20-9777'; DECLARE @Salary256 Money = 17369.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN256, 'Delia', 'Toone', @Salary256);
DECLARE @SSN257 char(11) = '420-28-0429'; DECLARE @Salary257 Money = 69381.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN257, 'Michael John', 'Troyer', @Salary257);
DECLARE @SSN258 char(11) = '236-75-2355'; DECLARE @Salary258 Money = 79299.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN258, 'Christie', 'Trujillo', @Salary258);
DECLARE @SSN259 char(11) = '984-20-5166'; DECLARE @Salary259 Money = 41036.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN259, 'Sairaj', 'Uddin', @Salary259);
DECLARE @SSN260 char(11) = '353-75-0098'; DECLARE @Salary260 Money = 23245.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN260, 'Sunil', 'Uppal', @Salary260);
DECLARE @SSN261 char(11) = '934-96-8406'; DECLARE @Salary261 Money = 62357.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN261, 'Jessie', 'Valerio', @Salary261);
DECLARE @SSN262 char(11) = '773-23-3159'; DECLARE @Salary262 Money = 21434.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN262, 'Gregory', 'Vanderbout', @Salary262);
DECLARE @SSN263 char(11) = '951-08-3331'; DECLARE @Salary263 Money = 72246.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN263, 'Michael', 'Vanderhyde', @Salary263);
DECLARE @SSN264 char(11) = '856-23-4990'; DECLARE @Salary264 Money = 18918.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN264, 'Margaret', 'Vanderkamp', @Salary264);
DECLARE @SSN265 char(11) = '359-67-5826'; DECLARE @Salary265 Money = 37729.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN265, 'Gary', 'Vargas', @Salary265);
DECLARE @SSN266 char(11) = '743-66-8203'; DECLARE @Salary266 Money = 61754.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN266, 'Nieves', 'Vargas', @Salary266);
DECLARE @SSN267 char(11) = '368-97-5673'; DECLARE @Salary267 Money = 19423.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN267, 'Ranjit', 'Varkey Chudukatil', @Salary267);
DECLARE @SSN268 char(11) = '890-04-1424'; DECLARE @Salary268 Money = 59489.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN268, 'Patricia', 'Vasquez', @Salary268);
DECLARE @SSN269 char(11) = '267-37-1036'; DECLARE @Salary269 Money = 11749.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN269, 'Wanda', 'Vernon', @Salary269);
DECLARE @SSN270 char(11) = '101-14-5907'; DECLARE @Salary270 Money = 58459.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN270, 'Robert', 'Vessa', @Salary270);
DECLARE @SSN271 char(11) = '148-51-2717'; DECLARE @Salary271 Money = 83361.00; INSERT INTO [dbo].[Employees] ([SSN], [FirstName], [LastName], [Salary]) VALUES (@SSN271, 'Caroline', 'Vicknair', @Salary271);

INSERT INTO [dbo].[AspNetRoles] (
  [Id]
  , [Name]
  , [NormalizedName]
  , [ConcurrencyStamp]
)
VALUES (2, 'Auditor', 'Auditor', NULL);

INSERT INTO [dbo].[AspNetRoles] (
  [Id]
  , [Name]
  , [NormalizedName]
  , [ConcurrencyStamp]
)
VALUES (1, 'HRManager', 'HRManager', NULL);

INSERT INTO [dbo].[AspNetUsers] (
	  [Id]
      ,[UserName]
      ,[NormalizedUserName]
      ,[Email]
      ,[NormalizedEmail]
      ,[EmailConfirmed]
      ,[PasswordHash]
      ,[SecurityStamp]
      ,[ConcurrencyStamp]
      ,[PhoneNumber]
      ,[PhoneNumberConfirmed]
      ,[TwoFactorEnabled]
      ,[LockoutEnd]
      ,[LockoutEnabled]
      ,[AccessFailedCount]
)
VALUES (
	'23dc01d7-fb80-4e64-9851-7d540866732d'
	, 'rachel@contoso.com'
	, 'RACHEL@CONTOSO.COM'
	, 'rachel@contoso.com'
	, 'RACHEL@CONTOSO.COM'
	, 1
	, 'AQAAAAEAACcQAAAAEIoraEzOKP3gywgo+Q7Mj/6ljYUbuaQLHA70v+cnus2JwiaTbE/xokWOr+7jM4Cksw=='
	, 'U3UZHU63YJITH63GTS2QUVC63INHGEUC'
	, '68cc60f2-dda3-4227-84a8-64b4e7b03e89'
	, NULL
	, 0
	, 0
	, NULL
	, 1
	, 0
);

INSERT INTO [dbo].[AspNetUsers] (
	  [Id]
      ,[UserName]
      ,[NormalizedUserName]
      ,[Email]
      ,[NormalizedEmail]
      ,[EmailConfirmed]
      ,[PasswordHash]
      ,[SecurityStamp]
      ,[ConcurrencyStamp]
      ,[PhoneNumber]
      ,[PhoneNumberConfirmed]
      ,[TwoFactorEnabled]
      ,[LockoutEnd]
      ,[LockoutEnabled]
      ,[AccessFailedCount]
)
VALUES (
	'68aec293-a9e1-4b72-8a07-dd869f0ab119'
	, 'alice@contoso.com'
	, 'ALICE@CONTOSO.COM'
	, 'alice@contoso.com'
	, 'ALICE@CONTOSO.COM'
	, 1
	, 'AQAAAAEAACcQAAAAELP4ohm+ICIVcEUgqVBudM7ksgknW1X+Cyo+N9lBhMxAFEeJO+S+yo5HEVksc1aOpw=='
	, '4Q7OJLZYKVQOXROFCVMZZA55ME76VWPV'
	, 'df582ae0-db2f-4cda-838b-1b020e80970b'
	, NULL
	, 0
	, 0
	, NULL
	, 1
	, 0
);

INSERT INTO [dbo].[AspNetUserRoles] (
	[UserId]
    ,[RoleId]
)
VALUES ('23dc01d7-fb80-4e64-9851-7d540866732d', 1);

INSERT INTO [dbo].[AspNetUserRoles] (
	[UserId]
    ,[RoleId]
)
VALUES ('68aec293-a9e1-4b72-8a07-dd869f0ab119', 2);