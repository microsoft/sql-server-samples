$(() => {
    var $table = $("#orders").DataTable();
    var $formOrder = $("#EditOrderForm");
    var $orderLines =
        $("#orderLines")
            .DataTable({
                ajax: {
                    url: "/OData/SalesOrderLines?$top=0",
                    dataSrc: "value"
                },
                columns: [
                    { data: "Description" },
                    { data: "Quantity", defaultContent: "" },
                    { data: "UnitPrice", defaultContent: "" },
                    { data: "TaxRate", defaultContent: "" },
                    { data: "ProductName", defaultContent: "" },
                    { data: "ColorName", defaultContent: "" },
                    { data: "PackageTypeName", defaultContent: "" }
                ]
            });

    $table.on("click", "button.edit",
        e => {
            e.preventDefault();
            $formOrder[0].reset();
            var id = e.target.attributes["data-id"].value;
            o('SalesOrders')
                .find(id)
                .get()
                .then(model => {
                    $orderLines.clear().draw();
                    $("body").trigger("open-order-edit");
                    $formOrder.view(model.data);
                    $orderLines.ajax.url("/OData/SalesOrderLines?$filter=OrderID eq " + id);
                    $orderLines.ajax.reload();
                })
                .fail(e => {
                    toastr.error('An error occured while trying to get the sales order.');
                    console.error(e);
                });
        });

    $("button#save-order").on("click",
        e => {
            var id = $("#OrderID", $formOrder).val();
            var state = $formOrder.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true });
            var request;
            if (id) {
                request = o('SalesOrders').find(id).put(state);
            } else {
                request = o('SalesOrders').post(state);
            }

            request
                .save()
                .then(model => {
                    toastr.success('The sales order is successfully saved.');
                    $table.ajax.reload();
                    $("body").trigger("close-order-edit");
                    $formOrder[0].reset();
                })
                .fail(e => {
                    toastr.error('An error occured while trying to save the sales order.');
                    console.error(e);
                });
        });

    $("button#cancel-order-edit").on("click",
        e => {
            $("body").trigger("close-order-edit");
            $formOrder[0].reset();
        });
});