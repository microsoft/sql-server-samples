$(() => {

    $.ajax('/odata/Customers?$apply=groupby((PostalCity),aggregate(CustomerID with sum as Total))&$orderby=CustomerID with sum desc&$top=5', { dataType: 'json' })
        .done(data => {
            $("#part1 table tbody tr").view(data.value);
        });

    $.ajax('/odata/SalesOrderLines?$apply=groupby((ColorName),aggregate(Quantity mul UnitPrice with sum as Total))', { dataType: 'json' })
        .done(data => {

            nv.addGraph(function () {
                var chart = nv.models.pieChart()
                    .x(function (d) { return d.ColorName; })
                    .y(function (d) { return d.Total; })
                    .labelType("percent")
                    .labelThreshold(0.15)
                    .height(200)
                    .showLabels(true);

                d3.select("#part2 svg")
                    .datum(data.value)
                    .transition().duration(350)
                    .call(chart);

                return chart;
            });
        });

    $.ajax('/odata/PurchaseOrderLines?$apply=groupby((ColorName),aggregate(OrderedOuters mul ExpectedUnitPricePerOuter with sum as Total))', { dataType: 'json' })
        .done(data => {

            nv.addGraph(function () {
                var chart = nv.models.pieChart()
                    .x(function (d) { return d.ColorName })
                    .y(function (d) { return d.Total })
                    .labelType("value")
                    .labelThreshold(.05)
                    .height(200)
                    .showLabels(true)
                    .donut(true);

                d3.select("#part3 svg")
                    .datum(data.value)
                    .transition().duration(350)
                    .call(chart);

                return chart;
            });

        });


    $.ajax('/odata/SalesOrderLines?$apply=groupby((PickingCompletedWhen),aggregate(Quantity mul UnitPrice with sum as Total))&$orderby=PickingCompletedWhen desc&$filter=PickingCompletedWhen ge \'2000-01-01\'', { dataType: 'json' })
        .done(data => {

            nv.addGraph(function () {

                var chart = nv.models.lineChart()
                    .margin({ right: 100 })
                    .x(function (d) { return new Date(d.PickingCompletedWhen).getTime(); })   //We can modify the data accessor functions...
                    .y(function (d) { return d.Total; })   //...in case your data is formatted differently.
                    .useInteractiveGuideline(true)    //Tooltips which show all data points. Very nice!
                    .rightAlignYAxis(true)      //Let's move the y-axis to the right side.
                    .height(250)
                    .showXAxis(true)
                    .showYAxis(true);

                //Format x-axis labels with custom function.
                chart.xAxis
                    .tickFormat(function (d) {
                        return d3.time.format('%x')(new Date(d));
                    });

                d3.select("#part4 svg")
                    .datum([{
                        values: data.value,
                        key: 'Daily sales ($)',
                        color: '#2ca02c' }])
                    .call(chart);

                return chart;
            });

        });
});