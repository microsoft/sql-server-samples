$(document).ready(function () {
    var table = $("#employeeDatatable").DataTable({
        "processing": true,
        "serverSide": true,
        "filter": true,
        "ajax": {
            "url": "/api/employee",
            "type": "POST",
            "datatype": "json"
        },
        "columnDefs": [
            {
                "targets": [0],
                "visible": false,
                "searchable": false
            }
        ],
        "columns": [
            { "data": "employeeId", "name": "EmployeeId", "autoWidth": true },
            { "data": "ssn", "name": "Ssn", "autoWidth": true },
            { "data": "firstName", "name": "FirstName", "autoWidth": true },
            { "data": "lastName", "name": "LastName", "autoWidth": true },
            { "data": "salary", "name": "Salary", render: $.fn.dataTable.render.number(',', '.',0), "autoWidth": true }
        ]
    });

    $(function () {
        $("#slider-range").slider({
            range: true,
            min: 0,
            max: 100000,
            values: [0, 100000],
            slide: function (event, ui) {
                $("#amount").val("$" + ui.values[0] + " - $" + ui.values[1]);
                var from = ui.values[0];
                var to = ui.values[1];
                table
                    .column(4) //---> THIS IS ID OF THE Salary column
                    .search(from + ":" + to)
                    .draw();
            }
        });
        $("#amount").val("$" + $("#slider-range").slider("values", 0) +
            " - $" + $("#slider-range").slider("values", 1));
    });
});  