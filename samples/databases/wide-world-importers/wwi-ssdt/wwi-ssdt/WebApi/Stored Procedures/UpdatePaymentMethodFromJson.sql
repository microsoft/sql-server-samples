CREATE PROCEDURE [WebApi].[UpdatePaymentMethodFromJson](@PaymentMethod NVARCHAR(MAX), @PaymentMethodID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Application.PaymentMethods SET
		PaymentMethodName = json.PaymentMethodName,
		LastEditedBy = @UserID
	FROM OPENJSON (@PaymentMethod)
		WITH (PaymentMethodName nvarchar(50)) as json
	WHERE
		Application.PaymentMethods.PaymentMethodID = @PaymentMethodID

END