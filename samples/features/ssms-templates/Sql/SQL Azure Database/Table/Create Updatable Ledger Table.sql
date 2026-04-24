-- ==============================
-- Create Updatable Ledger Table Template
-- Use the Specify Values for Template Parameters command (Ctrl-Shift-M) to fill in the parameter values below.
--
-- For more details on ledger tables please refer to MSDN documentation:
-- https://docs.microsoft.com/azure/azure-sql/database/ledger-overview
--
-- To learn more how to use updatable ledger tables in your applications:
-- https://docs.microsoft.com/azure/azure-sql/database/ledger-updatable-ledger-tables
-- ==============================

IF OBJECT_ID('<schema_name, sysname, dbo>.<table_name, sysname, sample_ledger_table>', 'U') IS NOT NULL
    DROP TABLE <schema_name, sysname, dbo>.<ledger_table_name, sysname, sample_ledger_table>
GO

--Create updatable ledger table.
CREATE TABLE [<schema_name, sysname, dbo>].[<ledger_table_name, sysname, sample_ledger_table>]
(
    --The table must contain at least one user-defined column.
    <column1_name, sysname, c1> <column1_datatype, , char(10)>,

    --Ledger tables require GENERATED ALWAYS columns, which can be explicitly defined or auto-generated during table creation
    <ledger_start_transaction_id_name, sysname, ledger_start_transaction_id> BIGINT GENERATED ALWAYS AS TRANSACTION_ID START,
    <ledger_end_transaction_id_name, sysname, ledger_end_transaction_id> BIGINT GENERATED ALWAYS AS TRANSACTION_ID END,
    <ledger_start_sequence_number_name, sysname, ledger_start_sequence_number> BIGINT GENERATED ALWAYS AS SEQUENCE_NUMBER START,
    <ledger_end_sequence_number_name, sysname, ledger_end_sequence_number> BIGINT GENERATED ALWAYS AS SEQUENCE_NUMBER END
)
WITH
(
    --Set SYSTEM_VERSIONING to ON
    SYSTEM_VERSIONING = ON
    (
        --Option to specify the name of the ledger history table. If not supplied, the history table will be created with the
        --default name format: [<schema_name>].[MSSQL_LedgerHistoryFor_<ledger_table_objectid>]
        HISTORY_TABLE = [<history_table_schema_name, sysname, dbo>].[<history_table_name, sysname, sample_ledger_history>]
    ),
    --Set LEDGER = ON. This is optional if this is a ledger database
    LEDGER = ON
    (
        --Option to specify the name of the ledger view. If not supplied, the view will be created with the
        --default name format: [<schema_name>].[<ledger_table_name>_Ledger]
        LEDGER_VIEW = [<view_schema_name, sysname, dbo>].[<view_name, sysname, sample_ledger_view>]
        (
            --Options to specify ledger view default column names
            TRANSACTION_ID_COLUMN_NAME = <transaction_id_column_name,, ledger_transaction_id>,
            SEQUENCE_NUMBER_COLUMN_NAME = <sequence_number_column_name,, ledger_sequence_number>,
            OPERATION_TYPE_COLUMN_NAME = <operation_type_id_column_name,, ledger_operation_type>,
            OPERATION_TYPE_DESC_COLUMN_NAME = <operation_type_desc_column_name,, ledger_operation_type_desc>
        )
    )
)

