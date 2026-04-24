$(function () {

    //$.ajax('data/nvd3-pie.js', { "dataType": "json" })
    $.ajax('api/Product/report1', { "dataType": "json" })
        .done(function (testdata) {

            var width = 300;
            var height = 300;

            nv.addGraph(function () {
                var chart =
                    nv.models
                    .pie()
                        .width(width)
                        .height(height)
                        .labelType(function (d, i, values) {
                            return values.key + ':' + values.value;
                        });

                d3.select("#pie1")
                        .datum([testdata])
                        .transition().duration(1200)
                        .attr('width', width)
                        .attr('height', height)
                        .call(chart);

                return chart;
            });

            nv.addGraph(function () {
                var chart = nv.models.pie()
                        .x(function (d) { return d.key; })
                        .y(function (d) { return d.y; })
                        .width(width)
                        .height(height)
                        .labelType('percent')
                        .valueFormat(d3.format('%'))
                        .donut(true);

                d3.select("#pie2")
                        .datum([testdata])
                        .transition().duration(1200)
                        .attr('width', width)
                        .attr('height', height)
                        .call(chart);

                return chart;
            });

        });

    //$.ajax('data/nvd3-multibar.js', { "dataType": "json" })
    $.ajax('api/Product/report2', { "dataType": "json" })
             .done(function (exampleData) {

                 nv.addGraph(function () {
                     var chart = nv.models.multiBarChart()
                       .reduceXTicks(true)   //If 'false', every single x-axis tick label will be rendered.
                       .rotateLabels(0)      //Angle to rotate x-axis labels.
                       .showControls(false)   //Allow user to switch between 'Grouped' and 'Stacked' mode.
                       .groupSpacing(0.1)    //Distance between each group of bars.
                     ;

                     chart.yAxis
                         .tickFormat(d3.format(',.1f'));

                     d3.select('svg#chart1')
                         .datum(exampleData)
                         .call(chart);

                     nv.utils.windowResize(chart.update);

                     return chart;
                 });
             });
});