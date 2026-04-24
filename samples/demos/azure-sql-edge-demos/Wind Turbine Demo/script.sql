-- TABLES --
/****** Object:  Table [dbo].[RealtimeSensorRecord] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].RealtimeSensorRecord(
	[RecordId] [uniqueidentifier] NOT NULL,
	[TurbineId] [varchar](50) NULL,
	[SensorType] [varchar](50) NULL, --
	[SensorId] [varchar](50) NULL,
	[SensorValue] [real] NULL,
	[Timestamp] [datetime] NULL

PRIMARY KEY CLUSTERED
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

-- STORE PROCEDURES --
/* Store procedure that clean up the sensor records table */
CREATE PROCEDURE [dbo].[TruncateRealtimeSensorRecords]
AS
DECLARE @SQL VARCHAR(2000)
SET @SQL='TRUNCATE TABLE dbo.RealtimeSensorRecord'
EXEC (@SQL);


-- Run Model Store Procedure
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID ( 'RunModel', 'P' ) IS NOT NULL
    DROP PROCEDURE RunModel;
GO

CREATE PROCEDURE [dbo].RunModel
	@Result INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @model VARBINARY(max) = (
		SELECT DATA
        FROM dbo.models
        WHERE id = 1
    )

	;WITH predict_input AS (
		SELECT WindSpeedStdDev, TurbineSpeedStdDev, OverallWindDirection, TurbineWindDirection,
			WindSpeedAverage, WindTempAverage, GearboxOilLevel, GearboxOilTemp, GeneratorActivePower,
			GeneratorSpeed, GeneratorTemp, GeneratorTorque, GridFrequency, GridVoltage,
			HydraulicOilPressure, NacelleAngle, PitchAngle, Vibration, TurbineSpeedAverage
		FROM
		(
		  SELECT SensorValue, SensorType, timestamp
		  FROM RealtimeSensorRecord
		  GROUP BY SensorValue, SensorType, timestamp
		) d
		PIVOT
		(
		  MAX(SensorValue)
		  FOR SensorType IN (WindSpeedStdDev, TurbineSpeedStdDev, OverallWindDirection, TurbineWindDirection,
			WindSpeedAverage, WindTempAverage, GearboxOilLevel, GearboxOilTemp, GeneratorActivePower,
			GeneratorSpeed, GeneratorTemp, GeneratorTorque, GridFrequency, GridVoltage,
			HydraulicOilPressure, NacelleAngle, PitchAngle, Vibration, TurbineSpeedAverage)
		) piv
	)

	SELECT @Result = p.output_label
	FROM PREDICT(MODEL = @model, DATA = predict_input) WITH (output_label bigint) AS p
END
GO
