ROOT_API_URL = "/api/Product/";

// ProductController is an object that contains actions the will be executed on
// get, save (create or update), delete
var ProductController =
    function ($table, $modal, $modalAddProduct) {

        return {

            getProduct: function (productID) {
                $.ajax({ url: ROOT_API_URL + productID, cache: false })
                    .done( function (json) {
                        $modal.loadJSON(json);
                    })
                    .fail(function () {
                        toastr.error('An error occured while trying to get the product.');
                    });
            },

            saveProduct: function (productID, product) {
                $.ajax({
                    contentType: 'application/json',
                    method: (productID === null) ? "POST" : "PUT",
                    url: ROOT_API_URL + (productID||""),
                    processData: false,
                    data: product,
                }).fail(function (msg) {
                    toastr.error('An error occured while trying to save the product.');
                }).done(function () {
                    toastr.success("Product is successfully saved!");
                    $table.ajax.reload(null, false);
                    if (productID === null)
                        $modalAddProduct.modal('hide');
                    else
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

    var $table = $('#example').DataTable();

    // Bootstrap modal setup
    $modalEditProduct = $('#modalEditProduct');
    $modalEditProduct.on('hide.bs.modal', function () {
        $(this).find("input[type!=checkbox],textarea,select").val('').end();
        $(this).find("input:checkbox").prop('checked', false);
    });

    $("#cancelEditButton", $modalEditProduct).on("click", function () {
        $modalEditProduct.modal('hide');
    });

    $modalAddProduct = $('#modalAddProduct');
    $modalAddProduct.on('hide.bs.modal', function () {
        $(this).find("input[type!=checkbox],textarea,select").val('').end();
        $(this).find("input:checkbox").prop('checked', false);
    });

    $("#cancelAddButton", $modalAddProduct).on("click", function () {
        $modalAddProduct.modal('hide');
    });
    // end modal setup

    var ctrl = ProductController($table, $modalEditProduct, $modalAddProduct);

    $table.on("click", "button.edit",
        function () {
            ctrl.getProduct(this.attributes["data-id"].value);
        });

    $table.on("click", "button.delete",
        function () {
            ctrl.deleteProduct(this.attributes["data-id"].value);
        });

    $('body').on("click", "#submitEditButton",
        function (e) {
            e.preventDefault();
            var $form = $("#EditProductForm");
            var productId = $("#ProductID", $form).val();
            var product = JSON.stringify($form.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true }));
            ctrl.saveProduct(productId, product);
    });

    $('body').on("click", "#submitAddButton",
    function (e) {
        e.preventDefault();
        var $form = $("#AddProductForm");
        var product = JSON.stringify($form.serializeJSON({ checkboxUncheckedValue: "false", parseAll: true }));
        ctrl.saveProduct(null, product);
    });

    $('body').on("click", "#submitAddButton2",
    function (e) {
        e.preventDefault();
        var $form = $("#AddProductForm");
        $form.submit();
    });
});