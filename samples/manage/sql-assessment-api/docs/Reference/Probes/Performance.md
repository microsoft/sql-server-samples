# Performance probe

**Type code:** *Performance*

Performance probe returns values for performance counters. This probe is meant to be used with [**performance**](../DataTransformation/performance.md) transform.

## Implementation properties

Implementation part of the probe definition contains the following parameters.

| Parameter       | Required | Type   | Default | Description                              |
|-----------------|:--------:|:------:|:-------:|------------------------------------------|
| numberOfSamples | Optional | number |    2    | Number of samples taken                     |
| interval        | Optional | number |    1    | Time interval between samples in seconds |
| counters        | Required | object |         | The list of performance counters         |

![Performance probe structure diagram](../../Customization/img/BasicPerformanceProbeStructure.svg)

## Performance counters list

The list of performance counters is represented by a JSON object. Each property is for performance objects, e.g. *'Latches'*, *'Databases'*, *'Buffer Manager'*. Each performance object has a JSON object, where each property represents a performance counter.

Counter names often contain spaces and other non-alphanumeric characters. That is why each counter must have an alias. Counter alias is the name which will be used in check conditions and messages.

Optionally, counter may have a list of specific instances of interest.

In the following example the probe retrieves *'Page Allocated/sec'* metric for *'Access Methods'* and returns samples as *page_allocated* values.

```json
{
  "type": "Performance",
  "implementation": {
    "Counters": {
      "Access Methods": {
        "Pages Allocated/sec": "pages_allocated"
      }
    }
  }
}
```

In the next example the probe takes only one sample for *'Free Node memory (KB)'*.

```json
{
  "type": "Performance",
  "implementation": {
    "NumberOfSamples": 1,
    "Counters": {
      "Memory Node": {
        "Free Node Memory (KB)": "free_node_memory"
      }
    }
  }
}
```

In the third example the probe returns data for two performance objects *'Memory Node'* and *'Access Methods'*. For the *'Free Node Memory (KB)'* counter it returns data for *'000'* instance only.

```json
{
  "type": "Performance",
  "implementation": {
    "NumberOfSamples": 1,
    "Counters": {
      "Memory Node": {
        "Free Node Memory (KB)": {
          "alias": "free_node_memory",
          "instances": ["000"]
        },
        "Target Node Memory (KB)": "target_node_memory"
      },
      "Access Methods": {
        "Pages Allocated/sec": "pages_allocated"
      }
    }
  }
}
```

## Example ruleset

The following JSON object represents a complete rule set using performance counters.

```json
{
    "schemaVersion": "1.0",
    "name": "Performance Checks Example",
    "version": "1.0",
    "rules":[
        {
            "target": { "type": "Server" },
            "id": "TotalPages",
            "itemType": "definition",
            "displayName": "Buffer Manager Total pages",
            "description": "Use \"average\", \"min\", or \"max\" for counter type PERF_COUNTER_LARGE_RAWCOUNT(65792).",
            "message": "Total pages (@{total_pages}) is greater than 0",
            "condition": {
                "lt": ["@total_pages", 0]
            },
            "probes": [
                {
                    "id": "PerformanceProbe",
                    "transform": {
                        "type": "performance",
                        "counters": {
                            "total_pages": "average"
                        }
                    }
                }
            ]
        },
        {
            "target": { "type": "Server" },
            "id": "CacheHitRatio",
            "itemType": "definition",
            "displayName": "Buffer Manager cache hit ratio",
            "description": "Use \"ratio\" for counter type PERF_LARGE_RAW_FRACTION(537003264) and specify base PERF_LARGE_RAW_BASE(1073939712).",
            "message": "Cache hit ratio (@{cache_hit_ratio:P0}) is greater than 0",
            "condition": {
                "lt": ["@cache_hit_ratio", 0]
            },
            "probes": [
                {
                    "id": "PerformanceProbe",
                    "transform": {
                        "type": "performance",
                        "counters": {
                            "cache_hit_ratio": {
                                "type": "ratio",
                                "base": "cache_hit_ratio_base"
                            }
                        }
                    }
                }
            ]
        },
        {
            "target": { "type": "Server" },
            "id": "LatchWaitTime",
            "itemType": "definition",
            "displayName": "Average Latch Wait Time",
            "description": "Use \"delta_ratio\" for counter type PERF_AVERAGE_BULK(1073874176) and base PERF_LARGE_RAW_BASE(1073939712).",
            "message": "Average Latch Wait Time (@{latch_wait_time}ms.) is greater than 0",
            "condition": {
                "lt": ["@latch_wait_time", 0]
            },
            "probes": [
                {
                    "id": "PerformanceProbe",
                    "transform": {
                        "type": "performance",
                        "counters": {
                            "latch_wait_time": {
                                "type": "delta_ratio",
                                "base": "latch_wait_time_base"
                            }
                        }
                    }
                }
            ]
        },
        {
            "target": { "type": "Server" },
            "id": "TransactionsPerSec",
            "itemType": "definition",
            "displayName": "Database Transactions per sec",
            "description": "Use \"rate\" for counter type PERF_COUNTER_BULK_COUNT(272696576).",
            "message": "Transactions per sec (@{transactions_sec:0.##}sec.) for database @{instance_name} is greater than 0",
            "condition": {
                "or": [{"eq": ["@instance_name", "_Total"]}, {"le": ["@transactions_sec", 0]}]
            },
            "probes": [
                {
                    "id": "PerformanceProbe",
                    "transform": {
                        "type": "performance",
                        "counters": {
                            "transactions_sec": "rate"
                        }
                    }
                }
            ]
        },
        {
            "target": { "type": "Server" },
            "id": "TotalTransactionsPerSec",
            "itemType": "definition",
            "displayName": "Total Database Transactions per sec",
            "description": "Use \"rate\" for counter type PERF_COUNTER_BULK_COUNT(272696576).",
            "message": "Total Transactions per sec (@{transactions_sec:0.##}sec.) is greater than 0",
            "condition": {
                "lt": ["@transactions_sec", 0]
            },
            "probes": [
                {
                    "id": "PerformanceProbe",
                    "transform": {
                        "type": "performance",
                        "counters": {
                            "transactions_sec": {
                                "type": "rate",
                                "instance": "_Total"
                            }
                        }
                    }
                }
            ]
        }
    ],
    "probes":{
        "PerformanceProbe": [{
            "type": "Performance",
            "implementation": {
                "Counters": {
                    "Buffer Manager": {
                        "Buffer cache hit ratio": "cache_hit_ratio",
                        "Buffer cache hit ratio base": "cache_hit_ratio_base",
                        "Target pages": "total_pages"

                    },
                    "Latches": {
                        "Average Latch Wait Time (ms)": "latch_wait_time",
                        "Average Latch Wait Time Base": "latch_wait_time_base"
                    },
                    "Databases": {
                        "Transactions/sec": "transactions_sec"
                    }
                }
            }
        }]
    }
}
```

## How to use multiple performance counters in a single check

While using multiple performance counters for different instances an issue the results might not look as expected. Take a look at the following example.

```json
"probes": [
    {
        "id": "PerformanceProbe",
        "alias": "b",
        "transform": {
        "type": "performance",
            "counters": {
                "batch_request_sec": "rate",
                "lock_requests_sec": {
                    "type": "rate",
                    "instance": "_Total"
                }
            }
        }
    }
]
```

The code worked as expected. The data transform returned two rows of data from the Performance probe:

| batch_request_sec | lock_requests_sec | instance_name           |
|:-----------------:|:-----------------:|:-----------------------:|
|              123s |              null | ‘’ no instance selected |
|              Null |              456s |                ‘_Total’ |

The condition is checked once per row and triggers a message for the first one and an error for another.

The following JSON illustrates a solution. The Performance probe is referenced twice. The first reference gets `batch_request_sec` rate. The second one gets `lock_requests_sec` rate for the `_Total` instance. Note [aliases](../../Customization/ProbeReference.md#alias) associated with each probe reference.

```json
"probes": [
    {
        "id": "PerformanceProbe",
        "alias": "b",
        "transform": {
        "type": "performance",
            "counters": {
                "batch_request_sec": "rate"
            }
        }
    },
    {
        "id": "PerformanceProbe",
        "alias": "l",
        "transform": {
        "type": "performance",
            "counters": {
                "lock_requests_sec": {
                    "type": "rate",
                    "instance": "_Total"
                }
            }
        }
    }
]
```

[Alias](../../Customization/ProbeReference.md#alias) is any alternative name for the probe. Any data variable may be prefixed with an alias or a probe id. E.g. the following names refer to the same value in an unambiguous case:

```plain
@PerformanceProbe::batch_request_sec
@b::batch_request_sec
@batch_request_sec
```

Those two probe references result in the following data passed to the check:

| b::batch_request_sec | b::instance_name | l::lock_requests_sec| l::instance_name |
|:--------------------:|:----------------:|:-------------------:|:----------------:|
|                 123s | ‘’ no instance   |                456s |         ‘_Total’ |
