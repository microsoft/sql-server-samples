$(() => {
    var $table =
        $("#customers")
            .DataTable({
                ajax: "/Table/Customers",
                serverSide: true,
                processing: true,
                columns: [
                    { data: "CustomerName" },
                    { data: "CustomerCategoryName", defaultContent: "" },
                    { data: "PhoneNumber", defaultContent: "" },
                    { data: "FaxNumber", defaultContent: "" },
                    { data: "BuyingGroupName", defaultContent: "" },
                    {
                        data: "CustomerID",
                        sortable: false,
                        searchable: false,
                        render: function (data) {
                            return '<button data-id="' + data + '" class="btn btn-primary btn-sm edit glyphicon glyphicon-edit" data-toggle="modal" data-target="#modalDialog"> Edit</button>';
                        }
                    }
                ]
            });

    var $formCustomer = $("#EditCustomerForm");

    o('CustomerCategories')
        .select('CustomerCategoryID,CustomerCategoryName')
        .get(categories => $("#CustomerCategoryID", $formCustomer).view(categories));

    o('BuyingGroups')
        .select('BuyingGroupID,BuyingGroupName')
        .get(buyingGroups => $("#BuyingGroupID", $formCustomer).view(buyingGroups));

    var $formOrder = $("#EditOrderForm");

    $table.on("click", "button.edit",
        e => {
            $formCustomer[0].reset();
            var id = e.target.attributes["data-id"].value;
            o('Customers')
                .find(id)
                .get()
                .then(model => {
                    $("body").trigger("open-customer-edit");
                    $formCustomer.view(model.data);
                    var $orders = $("#orders").DataTable();
                    $orders.ajax.url("/OData/SalesOrders?$filter=CustomerID eq " + id);
                    $orders.ajax.reload();
                    var $customerTransactions = $("#customerTransactions").DataTable();
                    $customerTransactions.ajax.url("/OData/CustomerTransactions?$filter=CustomerID eq " + id);
                    $customerTransactions.ajax.reload();
                    var $invoices = $("#invoices").DataTable();
                    $invoices.ajax.url("/OData/Invoices?$filter=CustomerID eq " + id);
                    $invoices.ajax.reload();
                })
                .fail(e =>
                    toastr.error('An error occured while trying to get the customer.')
                );
        });

    $("button#cancel-customer-edit").on("click",
        e => {
            $("body").trigger("close-customer-edit");
        });

    $("button#save-customer").on("click",
        e => {
            var id = $("#CustomerID", $formCustomer).val();
            var state = $formCustomer.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true });
            var request;
            if (id) {
                request = o('Customers').find(id).put(state);
            } else {
                request = o('Customers').post(state);
            }

            request
                .save()
                .then(model => {
                    $table.ajax.reload();
                    $("body").trigger("close-customer-edit");
                    toastr.success('The customer is successfully saved.');
                })
                .fail(e => toastr.error('An error occured while trying to save the customer.'));
        }
    );

    // Transition rules
    $("body")
        .on("open-customer-edit", e => {
            var $orders = $("#orders").DataTable();
            $orders.clear().draw();
            $(".customer-list").addClass("hidden");
            $(".customer-edit").removeClass("hidden");
        })
        .on("close-customer-edit", e => {
            $(".customer-edit").addClass("hidden");
            $(".customer-list").removeClass("hidden");
            window.scrollTo(0, 0);
            $formCustomer[0].reset();
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