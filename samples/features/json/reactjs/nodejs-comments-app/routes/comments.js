var express = require('express');
var router = express.Router();

var db = require('../db.js');
var TYPES = require('tedious').TYPES;

/* GET comments. */
router.get('/', function (req, res) {
    db.stream("select * from comments for json path", db.createConnection(), res, '[]');
});

/* GET single comment. */
router.get('/:id', function (req, res) {

    var conn = db.createConnection();

    var request = db.createRequest("select * from comments where id = @id for json path, without_array_wrapper", conn);
    request.addParameter('id', TYPES.Int, req.params.id);
    db.stream(request, conn, res, '{}');
});

/* POST create comment. */
router.post('/', function (req, res) {

    var connection = db.createConnection();
    var request = db.createRequest("insert into Comments values (@author, @text)", connection);

    request.addParameter('author', TYPES.NVarChar, req.body.author);
    request.addParameter('text', TYPES.NVarChar, req.body.text);

    db.executeRequest(request, connection);
});

module.exports = router;