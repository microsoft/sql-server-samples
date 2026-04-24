
# AzMetadata probe

**Type code:** *AzMetadata*

Azure metadata probe returns data which can be retrieved by [Azure Instance Metadata Service](https://learn.microsoft.com/azure/virtual-machines/linux/instance-metadata-service). IMDS returns data as a JSON object. `AzMetadata` probe retrieves data by JSONPath.

When assessment is running remotely and Azure Graph is available, IMDS is emulated with a Kusto query.

## Implementation properties

Implementation part of the probe definition contains the following parameters.

| Parameter | Required | Type   | Default | Description                      |
|-----------|:--------:|:------:|:-------:|----------------------------------|
| query     | Required | String |         | JSONPath to the data to retrieve |
