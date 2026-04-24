CREATE PROCEDURE [WebApi].[UpdateColorFromJson](@Color NVARCHAR(MAX), @ColorID int, @UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Warehouse.Colors SET
		ColorName = json.ColorName,
		LastEditedBy = @UserID
	FROM OPENJSON (@Color)
		WITH (ColorName nvarchar(50)) as json
	WHERE
		Warehouse.Colors.ColorID = @ColorID

END