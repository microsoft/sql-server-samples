-- helper stored procedure to batch reservations

CREATE PROCEDURE BatchInsertReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
BEGIN
	DECLARE @tranCount int = 0;
	DECLARE @TS Datetime2;
	DECLARE @Char_TS NVARCHAR(23);
	DECLARE @CurrentSeq int = 0;

	SET @TS = SYSDATETIME();
	SET @Char_TS = CAST(@TS AS NVARCHAR(23));
	WHILE (@tranCount < @ServerTransactions)	
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			SET @CurrentSeq = NEXT VALUE FOR TicketReservationSequence ;
			EXEC InsertReservationDetails  @CurrentSeq, @RowsPerTransaction, @Char_TS, @ThreadID;
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() = -1
				ROLLBACK TRAN
			;THROW
		END CATCH
		SET @tranCount += 1;
	END
END
