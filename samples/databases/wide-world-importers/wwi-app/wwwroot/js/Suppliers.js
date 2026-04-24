$(() => {
    var $table =
        $("#suppliers")
            .DataTable({
                ajax: "/Table/Suppliers",
                serverSide: true,
                columns: [
                    { data: "SupplierName" },
                    { data: "SupplierCategoryName", defaultContent: "" },
                    { data: "PhoneNumber", defaultContent: "" },
                    { data: "FaxNumber", defaultContent: "" },
                    { data: "PrimaryContact", defaultContent: "" },
                    {
                        data: "SupplierID",
                        sortable: false,
                        searchable: false,
                        render: function (data) {
                            return '<button data-id="' + data + '" class="btn btn-primary btn-sm edit glyphicon glyphicon-edit" data-toggle="modal"> Edit</button>';
                        }
                    }
                ]
            });

    var $formSupplier = $("#EditForm");
    var $formOrder = $("#EditPurchaseOrderForm");

    o('SupplierCategories')
        .select('SupplierCategoryID,SupplierCategoryName')
        .get(list => $("#SupplierCategoryID", $formSupplier).view(list));

    o('DeliveryMethods')
        .select('DeliveryMethodID,DeliveryMethodName')
        .get(list => $("#DeliveryMethodID", $formOrder).view(list));

    $table.on("click", "button.edit",
        e => {
            $formSupplier[0].reset();
            var id = e.target.attributes["data-id"].value;
            o('Suppliers')
                .find(id)
                .get()
                .then(model => {
                    $formSupplier.view(model.data);
                    $("body").trigger("open-supplier-edit");
                    var $orders = $("#orders").DataTable();
                    $orders.clear().draw();
                    $orders.ajax.url("/OData/PurchaseOrders?$filter=SupplierID eq " + id);
                    $orders.ajax.reload();
                    var $transactions = $("#supplierTransactions").DataTable();
                    $transactions.ajax.url("/OData/SupplierTransactions?$filter=SupplierID eq " + id);
                    $transactions.ajax.reload();
                    var $stockItems = $("#stockItems").DataTable();
                    $stockItems.ajax.url("/OData/StockItems?$filter=SupplierID eq " + id);
                    $stockItems.ajax.reload();
                })
                .fail(e => toastr.error('An error occured while trying to get the supplier.'));
        });

    $("#cancel-supplier-edit").on("click",
        e => {
            $("body").trigger("close-supplier-edit");
        });

    $("button#save-supplier").on("click",
        e => {
            e.preventDefault();
            var id = $("#SupplierID", $formSupplier).val();
            var state = $formSupplier.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true });
            var request;
            if (id) {
                request = o('Suppliers').find(id).put(state);
            } else {
                request = o('Suppliers').post(state);
            }

            request
                .save()
                .then(model => {
                    toastr.success('The supplier is successfully saved.');
                    $("body").trigger("close-supplier-edit");
                    $table.ajax.reload();
                })
                .fail(e => toastr.error('An error occured while trying to save the supplier.'));
        }
    );

    // Transition rules
    $("body")
        .on("open-supplier-edit", e => {
            $(".supplier-edit").removeClass("hidden");
            $(".supplier-list").addClass("hidden");
        })
        .on("close-supplier-edit", e => {
            $(".supplier-edit").addClass("hidden");
            $(".supplier-list").removeClass("hidden");
            window.scrollTo(0, 0);
            $formSupplier[0].reset();
        })
        .on("open-order-edit", e => {
            $(".order-list").addClass("hidden");
            $(".order-edit").removeClass("hidden");
            window.scrollTo(0, 0);
        })
        .on("close-order-edit", e => {
            $(".order-list").removeClass("hidden");
            $(".order-edit").addClass("hidden");
            window.scrollTo(0, 0);
            $formOrder[0].reset();
        });

});