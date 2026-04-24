/*
DISCLAIMER: © 2016 Microsoft Corporation. All rights reserved. Sample scripts in this guide are not supported under any Microsoft standard support program or service.
The sample scripts are provided AS IS without warranty of any kind. Microsoft disclaims all implied warranties including, without limitation, any implied warranties
of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you.
In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever
(including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or
inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
*/

--Sample script to generate file name for ranges in vss backup instead of range buffer
-- create database.
create database test;
GO

use test;
GO
-- create a table such that each row is on a page
create table tab
	(ID INT IDENTITY NOT NULL PRIMARY KEY,
	 BIGSTRING VARCHAR(7996)
	 );
declare @dml NVARCHAR(300); --for query
declare @RowCount int; -- RowCount iterator
set @RowCount = 0;
set @dml = 'INSERT INTO tab(BIGSTRING) VALUES(REPLICATE(''a'', 7996));'

--Max row count we need to insert, 150k rows gives us close to 65kb buffer
--using below updates, I have kept it 200k which gives 98kb buffer, anything above
--64 kb will give us filename instead of range values.

declare @MaxRowCount int;
set @MaxRowCount = 200000;

--Insert the rows

while @RowCount < @MaxRowCount

begin
       exec(@dml);
       set @RowCount = @RowCount + 1;
end

-- TAKE THE FULL BACKUP HERE, We use betest.exe here.
--BETEST.EXE /B /E /T FULL /S backupdoc_full.txt /D c:\tools\sqlbetest\backup\full /C comp1_file.txt

-- here we update the rows I re-declared the variables as I executed it as separate script
-- I am updating every 17th row so, we update alternate extent, which will make range buffer big.

declare @dml NVARCHAR(300);
declare @RowCount int;
declare @MaxRowCount int;
set @MaxRowCount = 200000;
set @RowCount = 1;

while @RowCount < @MaxRowCount
begin
       set @dml = 'UPDATE tab set BIGSTRING = REPLICATE(''b'', 7996) where ID = ' + cast(@RowCount as varchar(10)) + ';';
       exec(@dml);
       set @RowCount = @RowCount + 16;
end


-- Take differential backup here.
--  BETEST.exe /B /E /T DIFFERENTIAL /Pre backupdoc_full.txt /S backupdoc_diff.txt /D c:\tools\sqlbetest\backup\diff /C comp1_file.txt




