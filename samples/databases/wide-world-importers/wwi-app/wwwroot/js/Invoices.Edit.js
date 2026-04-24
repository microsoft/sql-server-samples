$(() => {

    var $invoices = $("#invoices").DataTable();
    var $formInvoiceEdit = $("#EditInvoiceForm");
    var $dlgInvoiceEdit = $("#modalInvoiceDialog");

    o('DeliveryMethods')
        .select('DeliveryMethodID,DeliveryMethodName')
        .get(list => $("#DeliveryMethodID", $dlgInvoiceEdit).view(list));

    $invoices.on("click", "button.edit",
        e => {
            $formInvoiceEdit[0].reset();
            var id = e.target.attributes["data-id"].value;
            o('Invoices')
                .find(id)
                .get()
                .then(model => {
                    $formInvoiceEdit.view(model.data);
                    $dlgInvoiceEdit.modal('show');
                })
                .fail(e => toastr.error('An error occured while trying to get the invoice.'));
        });

    $("button#save-invoice").on("click",
        e => {
            var id = $("#InvoiceID", $formInvoiceEdit).val();
            var state = $formInvoiceEdit.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true });
            var request;
            if (id) {
                request = o('Invoices').find(id).put(state);
            } else {
                request = o('Invoices').post(state);
            }

            request
                .save()
                .then(model => {
                    toastr.success('The invoice is successfully saved.');
                    $dlgInvoiceEdit.modal('hide');
                    $invoices.ajax.reload();
                })
                .fail(e => toastr.error('An error occured while trying to save the invoice.'));
        }
    );
});