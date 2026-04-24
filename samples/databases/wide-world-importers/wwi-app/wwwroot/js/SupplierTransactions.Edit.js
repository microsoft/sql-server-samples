$(() => {

    var $form = $("#EditSupplierTransactionForm");
    var $dlg = $("#modalSupplierTransactionDialog");

    o('TransactionTypes')
        .select('TransactionTypeID,TransactionTypeName')
        .get(list => $("#TransactionTypeID", $dlg).view(list));

    o('PaymentMethods')
        .select('PaymentMethodID,PaymentMethodName')
        .get(list => $("#PaymentMethodID", $dlg).view(list));

    $("#supplierTransactions").DataTable().on("click", "button.edit",
        e => {
            $form[0].reset();
            var id = e.target.attributes["data-id"].value;
            o('SupplierTransactions')
                .find(id)
                .get()
                .then(model => $form.view(model.data))
                .fail(e => toastr.error('An error occured while trying to get the supplier transaction.'));
        });

    $("button#save-supplier-transaction").on("click",
        e => {
            var id = $("#SupplierTransactionID", $form).val();
            var state = $form.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true });

            o('SupplierTransactions').find(id).put(state)
            .save()
            .then(model => {
                toastr.success('The supplier transaction is successfully saved.');
                $dlg.modal('hide');
                $("#supplierTransactions").DataTable().ajax.reload();
            })
            .fail(e => toastr.error('An error occured while trying to save the supplier transaction.'));
        }
    );
});