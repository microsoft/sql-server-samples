PRINT 'Inserting System Parameters'
GO

DECLARE @myCityID            AS INT
DECLARE @myCityName          AS NVARCHAR(50)
DECLARE @myStateProvinceCode AS NVARCHAR(5)
DECLARE @myStateProvinceName AS NVARCHAR(50)
DECLARE @myAreaCode          AS NVARCHAR(3)

EXEC [DataLoadSimulation].[GetRandomCity]
  @CityID            = @myCityID            OUTPUT
, @CityName          = @myCityName          OUTPUT
, @StateProvinceCode = @myStateProvinceCode OUTPUT
, @StateProvinceName = @myStateProvinceName OUTPUT
, @AreaCode          = @myAreaCode          OUTPUT


DECLARE @CurrentDateTime datetime2(7) = '20200101';
DECLARE @EndOfTime datetime2(7) =  '99991231 23:59:59.9999999';

INSERT [Application].SystemParameters
    (DeliveryAddressLine1, DeliveryAddressLine2, DeliveryCityID,
     DeliveryPostalCode, DeliveryLocation,
     PostalAddressLine1, PostalAddressLine2, PostalCityID, PostalPostalCode,
     ApplicationSettings, LastEditedBy, LastEditedWhen)
VALUES
    (N'Suite 14', N'1968 Martin Luther King Junior Drive', @myCityID,
     N'94129', geography::Point(37.765786, -122.504086, 4326),
     N'PO Box 201158', N'Golden Gate Park', @myCityID, 94129,
     N'{
	"Site": {
		"SEO": {
			"Title": "WWI | Site",
			"Description": "Wide World Importers - Site",
			"StockItemTitleTemplate": "WWI | Site | StockItem {0}",
			"StockItemDescrTemplate": "StockItem {0} ({1}})"
		},
		"Menu": {
			"Home": {
				"Url": "/",
				"Alt": "Home"
			},
			"StockItems": {
				"Url": "/stockitem",
				"Alt": "Stock item search"
			},
			"Brands": {
				"Url": "/brand",
				"Alt": "Supplier listing"
			},
			"Contact": {
				"Url": "/contact-us",
				"Alt": "Contact",
				"email": "jane@wideworldimporters.com"
			}
		},
		"CSSTheme": "bootstrap-stockitems",
		"Home": {
			"Message": "New StockItems from Wide World Importers",
			"PromoCategories": ["Gadgets", "Toys"],
			"PromoCount": 5,
			"NewStockItemsCount": 5,
			"HotStockItemsCount": 5
		},
		"SearchResults": {
			"SeoTitleTemplate": "WWI | Site | {0} | {1}",
			"SeoDescrTemplate": "Wide World Importers | Stock Items {0} ({1}})",
			"FacetCount": 3
		}
	},
	"Customer": {
		"SEO": {
			"Title": "WWI | Customer Portal",
			"Description": "Wide World Importers - Customer Site",
			"StockItemTitleTemplate": "WWI | CustomerPortal | StockItem {0}"
		},
		"CSSTheme": "bootstrap-admin",
		"Dashboard": {
			"PromoCategories": "",
			"PromoCount": 5,
            "NewStockItemsCount": 5
		}
	},
	"Supplier": {
		"SEO": {
			"Title": "WWI | Supplier Portal"
		},
		"CSSTheme": "bootstrap-admin",
		"Dashboard": {
			"StockItemsPerPage": 10,
			"QuotesPerPage": 25
		},
		"Reports": {
			"TopSales": true,
			"ThisMonthSale": true
		}
	},
	"Warehouse": {
		"SEO": {
			"Title": "WWI | Warehouse Administration",
			"Description": "WorldWideImporters - Site",
			"StockItemTitleTemplate": "WWI | Site | StockItem {0}"
		},
		"CSSTheme": "bootstrap-admin"
	},
	"Logging": {
		"configuration": {
			"status": "error",
			"name": "RoutingTest",
			"packages": "org.apache.logging.log4j.test",
			"properties": {
				"property": {
					"name": "filename",
					"value": "target/rolling1/rollingtest-$${sd:type}.log"
				}
			},
			"ThresholdFilter": {
				"level": "debug"
			},
			"appenders": {
				"Console": {
					"name": "STDOUT",
					"PatternLayout": {
						"pattern": "%m%n"
					}
				},
				"List": {
					"name": "List",
					"ThresholdFilter": {
						"level": "debug"
					}
				},
				"Routing": {
					"name": "Routing",
					"Routes": {
						"pattern": "$${sd:type}",
						"Route": [{
							"RollingFile": {
								"name": "Rolling-${sd:type}",
								"fileName": "${filename}",
								"filePattern": "target/rolling1/test1-${sd:type}.%i.log.gz",
								"PatternLayout": {
									"pattern": "%d %p %c{1.} [%t] %m%n"
								},
								"SizeBasedTriggeringPolicy": {
									"size": "500"
								}
							}
						}, {
							"AppenderRef": "STDOUT",
							"key": "Audit"
						}, {
							"AppenderRef": "List",
							"key": "Service"
						}]
					}
				}
			},
			"loggers": {
				"logger": {
					"name": "EventLogger",
					"level": "info",
					"additivity": "false",
					"AppenderRef": {
						"ref": "Routing"
					}
				},
				"root": {
					"level": "error",
					"AppenderRef": {
						"ref": "STDOUT"
					}
				}
			}
		}
	}
}', 1, @CurrentDateTime);
GO
