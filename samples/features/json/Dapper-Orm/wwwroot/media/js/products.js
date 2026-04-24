ROOT_API_URL = "/api/Product/";

// ProductController is an object that contains actions the will be executed on
// get, save (create or update), delete
var ProductController =
    function ($table, $modal) {

        return {

            getProduct: function (productID) {
                $.ajax(ROOT_API_URL + productID, {dataType: "json"})
                    .done( function (json) {
                        $modal.view(json);
                    })
                    .fail(function () {
                        toastr.error('An error occured while trying to get the product.');
                    });

            },

            saveProduct: function (productID, product) {
                $.ajax({
                    contentType: 'application/json',
                    method: (productID == "") ? "POST" : "PUT",
                    url: ROOT_API_URL + productID,
                    processData: false,
                    data: product,
                }).fail(function (msg) {
                    toastr.error('An error occured while trying to save the product.');
                }).done(function () {
                    toastr.success("Product is successfully saved!");
                    $table.ajax.reload(null, false);
                    $modal.modal('hide');
                });
            },

            deleteProduct: function (productID) {
                $.ajax({
                    method: "DELETE",
                    url: ROOT_API_URL + productID
                }).fail(function (msg) {
                    toastr.error('An error occured while trying to delete the product.', 'Product cannot be deleted!');
                }).done(function () {
                    toastr.success("Product is successfully deleted!");
                    $table.ajax.reload(null, false);
                });
            }
        }
    };

$(document).ready(function () {

    // DataTable setup
    var $table = $('#example').DataTable({
        "ajax": {
                    "url": ROOT_API_URL,
                    "dataSrc": ""
        },
        "columns": [
            { "data": "Name" },
            { "data": "Color", "defaultContent": "" },
            { "data": "Price", sType: 'numeric', "defaultContent": "" },
            { "data": "Quantity", "defaultContent": "" },
            { "data": "MadeIn", "defaultContent": "" },
            { "data": "Tags", "defaultContent": "" },
            {
                "data": "ProductID",
                "sortable": false,
                "render": function (data) {
                    return '<button data-id="' + data + '" class="btn btn-primary btn-sm edit" data-toggle="modal" data-target="#myModal"><span class="glyphicon glyphicon-edit"></span> Edit</button>';
                }
            },
            {
                "data": "ProductID",
                "sortable": false,
                "render": function (data) {
                    return '<button data-id="' + data + '" class="btn btn-danger btn-sm delete"><span class="glyphicon glyphicon-remove"></span> Delete</button>';
                }
            }
        ]
    });// end DataTable setup

    // Bootstrap modal setup
    $modal = $('#myModal');

    $modal.on('hide.bs.modal', function () {
        $(this).find("input[type!=checkbox],textarea,select").val('').end();
        $(this).find("input:checkbox").prop('checked', false);
    });

    $("#cancelButton", $modal).on("click", function () {
        $modal.modal('hide');
    });
    // end modal setup

    var ctrl = ProductController($table, $modal);

    $table.on("click", "button.edit",
        function () {
            ctrl.getProduct(this.attributes["data-id"].value);
        });

    $table.on("click", "button.delete",
        function () {
            ctrl.deleteProduct(this.attributes["data-id"].value);
        });

    $('body').on("click", "#submitButton",
        function (e) {
            e.preventDefault();
            var $form = $("#ProductForm");
            var productId = $("#ProductID", $form).val();
            var product = JSON.stringify($form.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true }));
            ctrl.saveProduct(productId, product);
        });
});