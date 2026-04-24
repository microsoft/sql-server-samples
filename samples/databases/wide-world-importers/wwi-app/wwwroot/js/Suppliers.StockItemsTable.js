$(() => {

    $("#stockItems")
        .DataTable({
            ajax: { url: "/OData/StockItems?$top=0", dataSrc: "value" },
            processing: true,
            columns: [
                { data: "StockItemName" },
                { data: "SupplierName", defaultContent: "" },
                { data: "ColorName", defaultContent: "" },
                { data: "Brand", defaultContent: "" },
                { data: "Size", defaultContent: "" },
                {
                    data: "StockItemID",
                    "sortable": false,
                    "searchable": false,
                    "render": function (data) {
                        return '<button data-id="' + data + '" class="btn btn-primary btn-sm edit glyphicon glyphicon-edit" data-toggle="modal" data-target="#modalStockItemDialog"> Edit</button>';
                    }
                },
                {
                    data: "StockItemID",
                    "sortable": false,
                    "searchable": false,
                    "render": function (data) {
                        return '<button data-id="' + data + '" class="btn btn-danger btn-sm delete"><span class="glyphicon glyphicon-trash"></span> Delete</button>';
                    }
                }
            ]
        });
});