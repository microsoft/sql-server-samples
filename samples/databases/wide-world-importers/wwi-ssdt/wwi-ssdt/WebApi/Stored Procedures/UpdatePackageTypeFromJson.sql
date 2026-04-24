CREATE PROCEDURE [WebApi].[UpdatePackageTypeFromJson](@PackageType NVARCHAR(MAX), @PackageTypeID int,@UserID int)
WITH EXECUTE AS OWNER
AS BEGIN
	UPDATE Warehouse.PackageTypes SET
		PackageTypeName = json.PackageTypeName,
		LastEditedBy = @UserID
	FROM OPENJSON (@PackageType)
		WITH (PackageTypeName nvarchar(50)) as json
	WHERE
		Warehouse.PackageTypes.PackageTypeID = @PackageTypeID

END