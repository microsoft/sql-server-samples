PRINT 'Inserting Warehouse.Colors'
GO

DECLARE @CurrentDateTime datetime2(7) = '20200101'
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999'

INSERT Warehouse.Colors
  (ColorID, ColorName, LastEditedBy, ValidFrom, ValidTo)
VALUES
  (1,'Azure', 1, @CurrentDateTime, @EndOfTime)
, (2,'Beige', 1, @CurrentDateTime, @EndOfTime)
, (3,'Black', 1, @CurrentDateTime, @EndOfTime)
, (4,'Blue', 1, @CurrentDateTime, @EndOfTime)
, (5,'Charcoal', 1, @CurrentDateTime, @EndOfTime)
, (6,'Chartreuse', 1, @CurrentDateTime, @EndOfTime)
, (7,'Cyan', 1, @CurrentDateTime, @EndOfTime)
, (8,'Dark Brown', 1, @CurrentDateTime, @EndOfTime)
, (9,'Dark Green', 1, @CurrentDateTime, @EndOfTime)
, (10,'Fuchsia', 1, @CurrentDateTime, @EndOfTime)
, (11,'Gold', 1, @CurrentDateTime, @EndOfTime)
, (12,'Gray', 1, @CurrentDateTime, @EndOfTime)
, (13,'Hot Pink', 1, @CurrentDateTime, @EndOfTime)
, (14,'Indigo', 1, @CurrentDateTime, @EndOfTime)
, (15,'Ivory', 1, @CurrentDateTime, @EndOfTime)
, (16,'Khaki', 1, @CurrentDateTime, @EndOfTime)
, (17,'Lavender', 1, @CurrentDateTime, @EndOfTime)
, (18,'Light Brown', 1, @CurrentDateTime, @EndOfTime)
, (19,'Light Green', 1, @CurrentDateTime, @EndOfTime)
, (20,'Maroon', 1, @CurrentDateTime, @EndOfTime)
, (21,'Mauve', 1, @CurrentDateTime, @EndOfTime)
, (22,'Navy Blue', 1, @CurrentDateTime, @EndOfTime)
, (23,'Olive', 1, @CurrentDateTime, @EndOfTime)
, (24,'Orange', 1, @CurrentDateTime, @EndOfTime)
, (25,'Plum', 1, @CurrentDateTime, @EndOfTime)
, (26,'Puce', 1, @CurrentDateTime, @EndOfTime)
, (27,'Purple', 1, @CurrentDateTime, @EndOfTime)
, (28,'Red', 1, @CurrentDateTime, @EndOfTime)
, (29,'Royal Blue', 1, @CurrentDateTime, @EndOfTime)
, (30,'Salmon', 1, @CurrentDateTime, @EndOfTime)
, (31,'Silver', 1, @CurrentDateTime, @EndOfTime)
, (32,'Tan', 1, @CurrentDateTime, @EndOfTime)
, (33,'Teal', 1, @CurrentDateTime, @EndOfTime)
, (34,'Wheat', 1, @CurrentDateTime, @EndOfTime)
, (35,'White', 1, @CurrentDateTime, @EndOfTime)
, (36,'Yellow', 1, @CurrentDateTime, @EndOfTime)
GO
