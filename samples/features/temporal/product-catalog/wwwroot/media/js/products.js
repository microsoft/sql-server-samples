/* Formatting function for row details - modify as you need */
function format(d) {
    if (d.ProductHistory) {

        if (d.ProductHistory.length == 1 && $.isEmptyObject(d.ProductHistory[0]))
            return "<span style=\"padding-left:50px;\">No history for this product.</span>";

        var sTemplateTr = '<tr id="row"><td class="Name"></td><td class="Color"></td><td class="Size"></td><td class="Price"></td><td class="Quantity"></td><td class="ValidTo"></td><td><a class="ProductID ValidFrom restore" href="api/Product/restore">Restore<span class="ui-icon ui-icon-arrowthick-1-n" style="display:inline-block"></span></a></td></tr>';
        var innerTab = '', htAuditTrail = '';

        d.ProductHistory
            .sort(function (a, b) {
                return (a.ValidFrom < b.ValidFrom);
            });

        for (var ver in d.ProductHistory) {
            if (new Date(d.ProductHistory[ver].ValidTo).getYear() > 8000)
                continue;

            innerTab += ("<tr>" +
                            $(sTemplateTr).loadJSON(d.ProductHistory[ver]).html()
                        + "</tr>");
        }

        htAuditTrail =
            ('<table id="example" class="display" cellspacing="0" width="90%" style="padding-left:7%;padding-bottom:4%;padding-top:2%"><thead><tr><th>Product</th><th>Color</th><th>Size</th><th>Price</th><th>Quantity</th><th>Date Modified</th><th></th></tr></thead><tbody>'
             + innerTab
            + '</tbody></table>');

        return htAuditTrail;
    }

    if (d.ProductDifferences) {
        // `d` is the original data object for the row
        var diffTable = '<table cellpadding="5" cellspacing="0" border="0" style="padding-left:50px;">';

        if (d.ProductDifferences.length == 1 && $.isEmptyObject(d.ProductDifferences[0])) {
            diffTable += "<tr><td>No differences between the latest version and this version.</td></tr>";
        } else {
            for (var i in d.ProductDifferences) {
                diff = d.ProductDifferences[i];
                if (diff.Column == "ValidFrom" || diff.Column == "ValidTo")
                    continue;
                diffTable += "<tr><td>Today's " + diff.Column + ":</td><td>" + diff.v1 + '</td></tr>'
            }
        }

        diffTable += '</table>';
        return diffTable;
    }
}

jqdtAjaxSource = "/api/Product";

$(document).ready(function () {

    var table = $('#example').DataTable({
        "sAjaxSource": jqdtAjaxSource,
        "columns": [
            { "className": 'details-control', "orderable": false, "defaultContent": "" },
            { "data": "Name" },
            { "data": "Color", "defaultContent": "" },
            { "data": "Size", "defaultContent": "" },
            { "data": "Price", sType: 'numeric', "defaultContent": "" },
            { "data": "Quantity", "visible": true, "defaultContent": "" },
            { "data": "ValidTo", "visible": false, "defaultContent": "" }
        ],
        "order": [[1, 'asc']]
    });


    $("#example tbody").on('click', 'a.restore', function (e) {
        e.preventDefault();
        $restoreLink = $(this);
        $.ajax(this.href)
            .done(function () {
                $("#example").DataTable().ajax.reload(
                    function ()
                    {
                        alert("Product is successfully restored.");

                    }, false);

            })
    });

    // Add event listener for opening and closing details
    $('#example tbody').on('click', 'td.details-control', function () {
        var tr = $(this).closest('tr');
        var row = table.row(tr);

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
});

$(function () {
    $("#slider").slider({
        value: 0,
        min: 0,
        max: 12,
        slide: function (event, ui) {
            var d = new Date();
            var delta = (((d-new Date("2015-04-01T00:00:00.0000Z"))/1000.0/60/60/24/(365.4/12)) * ui.value )/ 12;
            d.setMonth(d.getMonth() - delta);
            if (ui.value == 0) {
                $("#example").DataTable().ajax.url(jqdtAjaxSource).load();
                $("span#snapshot").text('');
            } else {
                $("span#snapshot").text("("+d.toDateString()+")");
                $("#example").DataTable().ajax.url(jqdtAjaxSource + "?date=" + d.toISOString()).load();
            }
        }
    });
});