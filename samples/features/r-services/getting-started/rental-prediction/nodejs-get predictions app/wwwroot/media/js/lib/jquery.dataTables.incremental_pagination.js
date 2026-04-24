$.fn.dataTableExt.oPagination.incremental = {
    /*
     * Function: oPagination.incremental.fnInit
     * Purpose:  Initalise dom elements required for pagination with a list of the pages
     * Returns:  -
     * Inputs:   object:oSettings - dataTables settings object
     *           node:nPaging - the DIV which contains this pagination control
     *           function:fnCallbackDraw - draw function which must be called on update
     */
    "fnInit": function (oSettings, nPaging, fnCallbackDraw) {
        $(nPaging).prepend($("<ul class=\"pagination\"></ul>"));
        var ul = $("ul", $(nPaging));
        nFirst = document.createElement('li');
        nPrevious = document.createElement('li');
        nNext = document.createElement('li');

        $(nPrevious).append($('<span>' + (oSettings.oLanguage.oPaginate.sPrevious) + '</span>'));
        $(nFirst).append($('<span>1</span>'));
        $(nNext).append($('<span>' + (oSettings.oLanguage.oPaginate.sNext) + '</span>'));

        nFirst.className = "paginate_button first active";
        nPrevious.className = "paginate_button previous";
        nNext.className = "paginate_button next";


        ul.append(nPrevious);
        ul.append(nFirst);
        ul.append(nNext);

        $(nFirst).click(function () {
            oSettings.oApi._fnPageChange(oSettings, "first");
            fnCallbackDraw(oSettings);
        });

        $(nPrevious).click(function () {
            if (!(oSettings._iDisplayStart === 0)) {
                oSettings.oApi._fnPageChange(oSettings, "previous");
                fnCallbackDraw(oSettings);
            }
        });

        $(nNext).click(function () {
            if (!(oSettings.fnDisplayEnd() == oSettings.fnRecordsDisplay()
                ||
                oSettings.aiDisplay.length < oSettings._iDisplayLength)) {
                oSettings.oApi._fnPageChange(oSettings, "next");
                fnCallbackDraw(oSettings);
            }
        });

        /* Disallow text selection */
        $(nFirst).bind('selectstart', function () { return false; });
        $(nPrevious).bind('selectstart', function () { return false; });
        $(nNext).bind('selectstart', function () { return false; });

        // Reset dynamically generated pages on length/filter change.
        $(oSettings.nTable).DataTable().on('length.dt', function (e, settings, len) {
            $("li.dynamic_page_item", nPaging).remove();
        });

        $(oSettings.nTable).DataTable().on('search.dt', function (e, settings, len) {
            $("li.dynamic_page_item", nPaging).remove();
        });
    },

    /*
     * Function: oPagination.incremental.fnUpdate
     * Purpose:  Update the list of page buttons shows
     * Returns:  -
     * Inputs:   object:oSettings - dataTables settings object
     *           function:fnCallbackDraw - draw function which must be called on update
     */
    "fnUpdate": function (oSettings, fnCallbackDraw) {
        if (!oSettings.aanFeatures.p) {
            return;
        }

        /* Loop over each instance of the pager */
        var an = oSettings.aanFeatures.p;
        for (var i = 0, iLen = an.length ; i < iLen ; i++) {
            var buttons = an[i].getElementsByTagName('li');
            $(buttons).removeClass("active");

            if (oSettings._iDisplayStart === 0) {
                buttons[0].className = "paginate_buttons disabled previous";
                buttons[buttons.length - 1].className = "paginate_button enabled next";
            } else {
                buttons[0].className = "paginate_buttons enabled previous";
            }

            var page = Math.round(oSettings._iDisplayStart / oSettings._iDisplayLength) + 1;
            if (page == buttons.length-1 && oSettings.aiDisplay.length > 0) {
                $new = $('<li class="dynamic_page_item active"><span>' + page + "</span></li>");
                $(buttons[buttons.length - 1]).before($new);
                $new.click(function () {
                    $(oSettings.nTable).DataTable().page(page-1);

                    fnCallbackDraw(oSettings);
                });
            } else
                $(buttons[page]).addClass("active");

            if (oSettings.fnDisplayEnd() == oSettings.fnRecordsDisplay()
                ||
                oSettings.aiDisplay.length < oSettings._iDisplayLength) {
                buttons[buttons.length - 1].className = "paginate_button disabled next";
            }
        }
    }
};
