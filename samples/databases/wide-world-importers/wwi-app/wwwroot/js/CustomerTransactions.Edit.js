$(() => {

    var $table = $("#customerTransactions").DataTable();
    var $form = $("#EditCustomerTransactionForm");
    var $dlg = $("#modalCustomerTransactionDialog");

    o('TransactionTypes')
        .select('TransactionTypeID,TransactionTypeName')
        .get(list => $("#TransactionTypeID", $dlg).view(list));

    o('PaymentMethods')
        .select('PaymentMethodID,PaymentMethodName')
        .get(list => $("#PaymentMethodID", $dlg).view(list));

    $table.on("click", "button.edit",
        e => {
            $form[0].reset();
            var id = e.target.attributes["data-id"].value;
            o('CustomerTransactions')
                .find(id)
                .get()
                .then(model => $form.view(model.data))
                .fail(e => toastr.error('An error occured while trying to get the supplier transaction.'));
        });

    $("button#save-customer-transaction").on("click",
        e => {
            var id = $("#CustomerTransactionID", $form).val();
            var state = $form.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true });

            o('CustomerTransactions')
                .find(id)
                .put(state)
                .save()
                .then(model => {
                    toastr.success('The customer transaction is successfully saved.');
                    $dlg.modal('hide');
                    $table.ajax.reload();
                })
                .fail(e => {
                    toastr.error('An error occured while trying to save the customer transaction.');
                    console.error(e);
                });
        }
    );
});