var express = require('express');
var router = express.Router();
var TYPES = require('tedious').TYPES;

/* GET products. */
router.get('/', function (req, res) {
    req.sql("select ProductID, Name, Color, Price, Quantity, JSON_VALUE(Data, '$.MadeIn') as MadeIn, JSON_QUERY(Tags) as Tags from Product FOR JSON PATH, ROOT('data')")
        .into(res);
});

/* GET single product. */
router.get('/:id', function (req, res) {
    req.sql("select ProductID, Name, Color, Price, Quantity, JSON_VALUE(Data, '$.MadeIn') as MadeIn, JSON_QUERY(Tags) as Tags from Product where productid = @id for json path, without_array_wrapper")
        .param('id', req.params.id, TYPES.Int)
        .into(res, '{}');
});

/* POST create product. */
router.post('/', function (req, res) {

    req.sql("EXEC InsertProductFromJson @json")
        .param('json', req.body, TYPES.NVarChar)
        .exec(res);
});

/* PUT update product. */
router.put('/:id', function (req, res) {
    req.sql("EXEC UpdateProductFromJson @id, @json")
        .param('json', req.body, TYPES.NVarChar)
        .param('id', req.params.id, TYPES.Int)
        .exec(res);
});

/* DELETE delete product. */
router.delete('/:id', function (req, res) {
    req.sql("DELETE Product WHERE ProductId = @id")
        .param('id', req.params.id, TYPES.Int)
        .exec(res);
});

module.exports = router;