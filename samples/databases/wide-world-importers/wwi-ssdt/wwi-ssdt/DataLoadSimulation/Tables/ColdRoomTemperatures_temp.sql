CREATE TABLE DataLoadSimulation.[ColdRoomTemperatures_temp] (
    [ColdRoomTemperatureID] BIGINT                                      NOT NULL,
    [ColdRoomSensorNumber]  INT                                         NOT NULL,
    [RecordedWhen]          DATETIME2 (7)                               NOT NULL,
    [Temperature]           DECIMAL (10, 2)                             NOT NULL,
    [ValidFrom]             DATETIME2 (7)								NOT NULL,
    [ValidTo]               DATETIME2 (7)								NOT NULL,
    INDEX [IX_DataSimulation_ColdRoomTemperatures_ColdRoomSensorNumber]
		NONCLUSTERED HASH ([ColdRoomSensorNumber]) WITH (BUCKET_COUNT=100000)
		-- 100K was chosen as bucket_count, since this number is always a good starting point, and
		--   number of sensors is not expected to exceed 1 million. (if it were to exceed 1 million,
		--   a performance degradation would be expected)
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY=SCHEMA_ONLY);

