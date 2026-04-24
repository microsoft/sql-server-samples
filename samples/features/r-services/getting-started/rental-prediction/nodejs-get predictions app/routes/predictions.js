var express = require('express');
var router = express.Router();

var db = require('../db.js');
var TYPES = require('tedious').TYPES;




/* GET list of all predictions for a given year */
router.get('/', function (req, res) {

//Call stored proc and get predictions

    var conn = db.createConnection();

    var request = db.createRequest("EXEC get_rental_predictions 2015", conn);

    db.stream(request, conn, res, '[]');

});



module.exports = router;