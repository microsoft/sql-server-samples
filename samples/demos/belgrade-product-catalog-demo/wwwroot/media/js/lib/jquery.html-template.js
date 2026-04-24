/*
* File:        jquery.html-template.js
* Version:     0.9.0-Beta
* Author:      Jovan Popovic
*
* Copyright 2016 Jovan Popovic, all rights reserved.
*
* This source file is free software, under either the GPL v2 license or a
* BSD style license, as supplied with this software.
*
* This source file is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
* or FITNESS FOR A PARTICULAR PURPOSE.
*
* This file contains implementation of the JQuery templating engine that load JSON
* objects into the HTML code. It is based on Alexandre Caprais notemplate plugin
* with several enchancements that are added to this plugin.
*/

(function ($) {
    $.fn.loadJSON = function (obj, options) {

        function loadSelect(element, aoValues, name) {
            ///<summary>
            ///Load options into the select list
            ///</summary>
            ///<param name="element" type="select">Select list</param>
            ///<param name="aoValues" type="Array{value,text,selected}">Array of object containin the options</param>
            ///<param name="name" type="String">Name of the select list</param>

            for (i = 0; i < aoValues.length; i++) {
                $("<option/>")
                    .attr("value", aoValues[i].value)
                    .text(aoValues[i].text)
                    .attr("selected", aoValues[i].selected)
                    .appendTo($(element));
            }
        }

        function setElementValue(element, value, name) {
            var type = element.type || element.tagName;
            if (type == null) {
                type = element[0].type || element[0].tagName; //select returns undefined if called directly
                if (type == null) {
                    return;
                }
            }
            type = type.toLowerCase();
            switch (type) {

                case 'radio':
                    if (value.toString().toLowerCase() == element.value.toLowerCase()) {
                        $(element).attr("checked", "checked");
                    }
                    break;

                case 'checkbox':
                    if (value) {
                        $(element).attr("checked", true).attr("value",true);
                    }
                    break;
                case 'option':
                    $(element).attr("value", value.value);
                    $(element).text(value.text);
                    if (value.selected)
                        $(element).attr("selected", true);
                    break;
                case 'select-multiple':
                    var select = element[0];
                    if (element[0].options == null || typeof (element[0].options) == "undefined") {
                        select = element;
                    }
                    if (select.options.length > 1) {
                        //If select list is not empty use values array to select optionses
                        var values = value.constructor == Array ? value : [value];
                        //replaced element with element[0] ???? because now it reports that element.optons does not exists
                        for (var i = 0; i < select.options.length; i++) {
                            for (var j = 0; j < values.length; j++) {
                                select.options[i].selected |= select.options[i].value == values[j];
                            }
                        }
                    } else {
                        //ELSE: Instead of selecting values use values array to populate select list
                        loadSelect(element, value, name);
                    }
                    break;

                case 'select':
                case 'select-one':
                    if (typeof value == "string") {
                        $(element).val(value);
                    } else {
                        loadSelect(element, value, name);
                    }
                    break;
                case 'text':
                case 'hidden':
                case 'date':
                case 'datetime-local':
                    $(element).val(value);
                    //$(element).attr("value", value);
                    break;
                case 'a':
                    var href = $(element).attr("href");
                    var iPosition = href.indexOf('#');
                    if (iPosition > 1000000) {
                        href = href.substr(0, iPosition) + '&' + name + '=' + value + href.substr(iPosition)
                    } else {
                        iPosition = href.indexOf('?');
                        if (iPosition > 0) // if parameters in the URL exists add new pair using &
                            href += '&' + name + '=' + value;
                        else//otherwise attach pair to URL
                            href = href + '?' + name + '=' + value;
                    }
                    $(element).attr("href", href);
                    break;
                case 'img':

                    if (obj.constructor == "String") {
                        //Assumption is that value is in the HREF$ALT format
                        var iPosition = value.indexOf('$');
                        var src = "";
                        var alt = "";
                        if (iPosition > 0) {
                            src = value.substring(0, iPosition);
                            alt = value.substring(iPosition + 1);
                        }
                        else {
                            src = value;
                            var iPositionStart = value.lastIndexOf('/') + 1;
                            var iPositionEnd = value.indexOf('.');
                            alt = value.substring(iPositionStart, iPositionEnd);
                        }
                        $(element).attr("src", src);
                        $(element).attr("alt", alt);
                    } else {
                        $(element).attr("src", obj.src);
                        $(element).attr("alt", obj.alt);
                        $(element).attr("title", obj.title);
                    }
                    break;

                case 'textarea':
                case 'submit':
                case 'button':
                default:
                    try {
                        $(element).html(value.toString());
                    } catch (exc) { }
            }

        }

        function bind(obj, element, name) {

            // no object
            if (obj != undefined)
              if (obj.constructor == Object) {
                if (element.length >= 1 && element[0].tagName == "OPTION") {
                    setElementValue(element[0], obj, name);
                    //return;
                }
                for (var prop in obj) {
                    if (prop == null || typeof prop == "undefined")
                        continue;
                    else {
                        //Find an element with class, id, name, or rel attribute that matches the property name
                        var child = jQuery.makeArray(jQuery("." + prop, element)).length > 0 ? jQuery("." + prop, element) :
                                                    jQuery("#" + prop, element).length > 0 ? jQuery("#" + prop, element) :
                                                    jQuery('[name="' + prop + '"]', element).length > 0 ? jQuery('[name="' + prop + '"]', element) :
													jQuery('[rel="' + prop + '"]');
                        if (child.length != 0) {
                            bind(obj[prop], jQuery(child, element), prop);
                        }
                    }
                }
            }
            // array
            else if (obj.constructor == Array) {
                if (   (element.type == "select" || element.type == "select-one" || element.type == "select-multiple" ||
                        element[0].type == "select" || element[0].type == "select-one" || element[0].type == "select-multiple"
                    )) {

                    loadSelect(element, obj, name);
                    return;
                } else {
                    var arrayElements = $(element).children("[rel]");
                    if (arrayElements.length > 0) {//if there are rel=[index] elements populate them instead of iteration
                        arrayElements.each(function () {
                            var rel = $(this).attr("rel");
                            //setElementValue(this, obj[rel], name);
                            bind(obj[rel], $(this), name);
                        });
                    } else {//recursive iteration
                        var arr = jQuery.makeArray(element);
                        var template = $(arr[arr.length - 1]).clone(true);
                        //how many duplicate
                        var nbToCreate = obj.length;
                        var i = 0;
                        if (element[0] == null || (element[0] != null && element[0].tagName != "OPTION")) {
                            var iExist = 0;
                            for (iExist = 0; iExist < arr.length; iExist++) {
                                if (i < obj.length) {
                                    var elem = $(element).eq(iExist);
                                    bind(obj[i], elem, name);
                                }
                                i++;
                            }
                            var nbToCreate = obj.length - arr.length; ;
                        }
                        //fill started by last
                        i = obj.length - 1;
                        var iCreate = 0;
                        for (iCreate = 0; iCreate < nbToCreate; iCreate++) {
                            //duplicate the last
                            var last = template.clone(true).insertAfter(arr[arr.length - 1]);
                            bind(obj[i], last, name);
                            i--;
                        }
                    }
                }
            }
            // data only
            else {
                var value = obj;
                var type;
                if (element.length > 0) {
                    var i = 0;
                    for (i = 0; i < element.length; i++)
                        setElementValue(element[i], obj, name);
                }
                else {
                    setElementValue(element, obj, name);
                }
            }
        } //function bind end

        function init(placeholder) {
            if (placeholder.data("loadJSON-template") != null && placeholder.data("loadJSON-template") != "") {
                var template = placeholder.data("loadJSON-template");
                placeholder.html(template);
            } else {
                var template = placeholder.html()
                placeholder.data("loadJSON-template", template);
            }
        }

        var defaults = {
            onLoading: function () { },
            onLoaded: function () { }
        };

        properties = $.extend(defaults, options);

        return this.each(function () {

            if (obj.constructor == String) {
                obj = $.parseJSON(obj);
            }
            init($(this));
            properties.onLoading();
            bind(obj, this);
            properties.onLoaded();

        });
    };
})(jQuery);