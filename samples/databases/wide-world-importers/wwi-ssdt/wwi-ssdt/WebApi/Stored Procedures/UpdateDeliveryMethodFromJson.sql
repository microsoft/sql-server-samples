CREATE PROCEDURE [WebApi].[UpdateDeliveryMethodFromJson](@DeliveryMethod NVARCHAR(MAX), @DeliveryMethodID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Application.DeliveryMethods SET
		DeliveryMethodName = json.DeliveryMethodName,
		LastEditedBy = @UserID
	FROM OPENJSON (@DeliveryMethod)
		WITH (DeliveryMethodName nvarchar(50)) as json
	WHERE
		Application.DeliveryMethods.DeliveryMethodID = @DeliveryMethodID

END