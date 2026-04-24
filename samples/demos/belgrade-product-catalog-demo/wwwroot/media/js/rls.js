$(document).ready(function () {

    $.ajax("/api/Company").done(function (json) {
        $("#CompanyList").loadJSON(json);
    });

    $("li a.user-role").on("click", function () {
        localStorage.User = $(this).text();
    });

    $("span.UserGreeting").text(localStorage.User);
});