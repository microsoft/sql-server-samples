-- Defines external file format for the NYT data in Azure Blob Storage

CREATE EXTERNAL FILE FORMAT uncompressedcsv
WITH
(  FORMAT_TYPE = DELIMITEDTEXT
,   FORMAT_OPTIONS  ( FIELD_TERMINATOR  = ','
                    , STRING_DELIMITER  = ''
                    , DATE_FORMAT       = ''
                    , USE_TYPE_DEFAULT  = False
                    )
);

CREATE EXTERNAL FILE FORMAT compressedcsv
WITH
(  FORMAT_TYPE = DELIMITEDTEXT
,   FORMAT_OPTIONS  ( FIELD_TERMINATOR  = '|'
                    , STRING_DELIMITER  = ''
                    , DATE_FORMAT       = ''
                    , USE_TYPE_DEFAULT  = False
                    )
,   DATA_COMPRESSION = 'org.apache.hadoop.io.compress.GzipCodec'
);
