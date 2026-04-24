ROOT_API_URL = "/api/Product/";

$(document).ready(function () {

    // DataTable setup
    $('#example').DataTable({
        "ajax": ROOT_API_URL + "temporal",
        "columns": [
            { "className": 'details-control', "visible": true, "sortable": false, "searchable": false, "defaultContent": "" },
            { "data": "Name" },
            { "data": "Color", "defaultContent": "" },
            { "data": "Price", sType: 'numeric', "defaultContent": "" },
            { "data": "Quantity", "visible": true, "defaultContent": "" },
            { "data": "MadeIn", "visible": true, "defaultContent": "" },
            { "data": "Tags", "visible": true, "defaultContent": "" },
            {
                "data": "ProductID",
                "sortable": false,
                "searchable": false,
                "render": function (data) {
                    return '<button data-id="' + data + '" class="btn btn-primary btn-sm edit" data-toggle="modal" data-target="#modalEditProduct"><span class="glyphicon glyphicon-edit"></span> Edit</button>';
                }
            },
            {
                "data": "ProductID",
                "sortable": false,
                "searchable": false,
                "render": function (data) {
                    return '<button data-id="' + data + '" class="btn btn-danger btn-sm delete"><span class="glyphicon glyphicon-remove"></span> Delete</button>';
                }
            },
            {
                "data": "ProductID",
                "visible": false,
                "sortable": false,
                "searchable": false,
                "render": function (data, type, full) {
                    return '<a href="' + ROOT_API_URL + 'restore?ProductID=' + data + '&DateModified=' + full.DateModified + '" class="restore btn btn-success btn-sm delete"><span class="glyphicon glyphicon-floppy-open"></span> Restore</button>';
                }
            }
        ]
    });// end DataTable setup

});

$(function () {

    var $table = $('#example').DataTable();
    // Add event listener for opening and closing details
    $('#example tbody').on('click', 'td.details-control', function () {
        var tr = $(this).closest('tr');
        var row = $table.row(tr);

        if (row.child.isShown()) {
            // This row is already open - close it
            row.child.hide();
            tr.removeClass('shown');
        }
        else {
            // Open this row
            row.child(format(row.data())).show();
            tr.addClass('shown');
        }
    });

    $("#example tbody").on('click', 'a.restore', function (e) {
        e.preventDefault();
        $restoreLink = $(this);
        $.ajax(this.href)
            .done(function () {
                $("#example").DataTable().ajax.reload(
                    function ()
                    {
                        toastr.success("Product is successfully restored.");
                    }, false);

            })
    });
});

var TODAY = new Date();
var ONE_DAY = 24 * 60 * 60 * 1000; // hours*minutes*seconds*milliseconds
var DIFF_DAYS = Math.round(Math.abs((TODAY.getTime() - (new Date("2015-05-01T00:00:00.0000Z")).getTime()) / (ONE_DAY)));

$(function () {
    $("#slider").slider({
        value: 0,
        min: -DIFF_DAYS,
        max: 0,
        slide: function (event, ui) {

            var d = new Date();
            d.setDate(d.getDate() + ui.value);
            var $dt = $("#example").DataTable();
            var iColumnCount = $dt.columns().count();
            if (ui.value === 0) {

                $("#example").DataTable().ajax.url(ROOT_API_URL + 'temporal').load();
                $("span#snapshot").text('');

                $dt.columns(iColumnCount-3).visible(true);
                $dt.columns(iColumnCount-2).visible(true);
                $dt.columns(iColumnCount-1).visible(false);

            } else {

                $("#example").DataTable().ajax.url(ROOT_API_URL + 'temporal' + "?date=" + d.toISOString()).load();
                $("span#snapshot").text("(" + d.toDateString() + ")");
                $dt.columns(iColumnCount - 3).visible(false);
                $dt.columns(iColumnCount - 2).visible(false);
                $dt.columns(iColumnCount - 1).visible(true);
            }
        }
    });
});

/* Formatting function for row details - modify as you need */
function format(d) {
    if (d.ProductHistory) {

        if (d.ProductHistory.length === 1 && $.isEmptyObject(d.ProductHistory[0]))
            return "<span style=\"padding-left:50px;\">No history for this product.</span>";

        var sTemplateTr = '<tr class="auditrow"><td class="Name"></td></td><td class="Color"></td><td class="Price"></td><td class="Quantity"></td><td class="DateModified"><td class="ValidTo"></td><td><a class="ProductID DateModified restore" href="api/Product/restore">Restore<span class="ui-icon ui-icon-arrowthick-1-n" style="display:inline-block"></span></a></td></tr>';
        var innerTab = '', htAuditTrail = '';

        for (i = 0; i < d.ProductHistory.length; i++) {
            var ver = d.ProductHistory[i];
            if (new Date(ver.ValidTo).getYear() > 8000)
                continue;

            innerTab += ("<tr>" +
                            $(sTemplateTr).loadJSON(ver).html()
                        + "</tr>");
        }

        htAuditTrail =
            ('<table class="table table-striped history-table" cellspacing="0"><thead><tr><th>Product</th><th>Color</th><th>Price</th><th>Quantity</th><th>Date Modified</th><th>Valid To</th><th></th></tr></thead><tbody>'
             + innerTab
            + '</tbody></table>');

        return htAuditTrail;
    }

    if (d.ProductDifferences) {
        // `d` is the original data object for the row
        var diffTable = '';

        if (d.ProductDifferences.length === 1 && $.isEmptyObject(d.ProductDifferences[0])) {
            diffTable += "<tr><td>No differences between the latest version and this version.</td></tr>";
        } else {
            for (var i in d.ProductDifferences) {
                diff = d.ProductDifferences[i];
                if (diff.Column === "DateModified" || diff.Column === "ValidTo")
                    continue;
                diffTable += "<tr><td>Today's " + diff.Column + ":</td><td>" + diff.v1 + '</td></tr>'
            }
        }
        return '<table class="table table-striped">' + diffTable + '</table>';
    }
}