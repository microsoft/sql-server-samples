/*
* File:        jquery.view-engine.js
* Version:     1.0.1
* Author:      Jovan Popovic
*
* Copyright 2017 Jovan Popovic, all rights reserved.
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
    $.fn.view = function (obj, options) {

        if (!(typeof obj == "object")) {
            console.error("Object should be provided as a model instead of " + (typeof obj));
            throw "Object should be provided as a model instead of " + (typeof obj);
        }
        function loadSelect(nSelect, aoValues, name) {
            ///<summary>
            ///Load options into the select list
            ///</summary>
            ///<param name="nSelect" type="select">Select list</param>
            ///<param name="aoValues" type="Array{value,text,selected}">Array of object containin the options</param>
            ///<param name="name" type="String">Name of the select list</param>
            for (i = 0; i < aoValues.length; i++) {
                $("<option/>")
                    .attr("value", aoValues[i].value || aoValues[i])
                    .text(aoValues[i].text || aoValues[i])
                    .attr("selected", aoValues[i].selected)
                    .appendTo($(nSelect));
            }
        }

        function setElementValue(element, value, name) {
            var type = element.type || element.tagName;
            if (type == null && element.length == 1) {
                type = element[0].type || element[0].tagName; //select returns undefined if called directly
            }
            if (type==null)
                return;
            type = type.toLowerCase();
            switch (type) {

                case 'text':
                case 'hidden':
                case 'date':
                case 'week':
                case 'month':
                case 'time':
                case 'email':
                case 'url':
                case 'tel':
                case 'color':
                case 'datetime-local':
                case 'number':
                case 'range':
                case 'submit':
                case 'button':
                    $(element).val(value);
                break;

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

                case 'select':
                case 'select-one':
                case 'datalist':
                    if (typeof value == "string" || typeof value == "number" || typeof value == "boolean") {
                        $(element).val(value);
                    } else if (value.constructor == Array) {
                        loadSelect(element, value, name);
                    } else {
                        console.error("Cannot bind " + value + " to " + type);
                    }
                break;

                case 'select-multiple':
                    var select = element[0];
                    if (element[0].options == null || typeof (element[0].options) == "undefined") {
                        select = element;
                    }
                    if (select.options.length > 1) {
                        //If select list is not empty use values array to select options
                        var values = value.constructor == Array ? value : [value];
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

                case 'option':
                    var $option = $(element);
                    // value can be object {value,text,selected} or scalar
                    $option.attr("value", value.value || value);
                    $option.text(value.text || value.value || value);
                    if (value.selected)
                        $option.attr("selected", true);
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
                        else//otherwise attach the name=value pair to the URL
                            href = href + '?' + name + '=' + value;
                    }
                    $(element).attr("href", href);
                    break;
                case 'img':
                    var $img = $(element);
                    if (typeof value == "string") {
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
                        }
                        $img.attr("src", src);
                        $img.attr("alt", alt);
                    } else {
                        $img.attr("src", obj.src);
                        $img.attr("alt", obj.alt);
                        $img.attr("title", obj.title);
                    }
                    break;
                case 'form':
                    {
                        var $form = $(element);
                        if (typeof value == "string" || typeof value == "number") {
                            var action = $form.attr("action");
                            if (action.indexOf("{{" + name + "}}") > 0) {
                                $form.attr("action", action.replace("{{" + name + "}}", value));
                            } else {
                                $form.attr("action", action + value);
                            }
                        }
                        break;
                    }
                case 'textarea':
                default:
                    try {
                        $(element).html(value.toString());
                    } catch (exc) {
                        console.error(exc);
                    }
            }
        }

        function bind(data, domNode, name) {

            if (data == null)
                return;

            if (data.constructor == Object) {
                if (domNode.length >= 1 && domNode[0].tagName == "OPTION")
                {
                    // Shortcut: if tag is OPTION and data is object - set the value of OPTION
                    setElementValue(domNode[0], data, name);
                    return;
                }
                else {
                    for (var prop in data) {
                        if (prop == null || typeof prop == "undefined")
                            continue;
                        else {
                            //Find an element with class, id, or name that matches the property name
                            var sSelector = ".bind-" + prop + ", #" + prop + ', [name="' + prop + '"]';
                            bind(data[prop], jQuery(sSelector, domNode), prop);
                            }
                    }
                }
            }
            else if (data.constructor == Array) {
                if ( domNode.tagName == "SELECT" || domNode.tagName == "DATALIST"
                    || domNode.length == 1 && (domNode[0].tagName == "SELECT" || domNode[0].tagName == "DATALIST")
                ) {
                    setElementValue(domNode, data, name);
                    return;
                } else
                 {
                    // Clone the element that will be used as template (e.g. <li> or <tr>)
                    var template = $(domNode).clone(true);
                    for (var i = data.length - 1; i > 0 ; i--){
                        // Put the clone of template on the second place and puth other after.
                        var target = template.clone(true).insertAfter( $(domNode));
                        // Bind i-th object into the new placeholder.
                        bind(data[i], target, name);
                    }
                    // Bind 0-th object into the element used as a prototype (the first one).
                    bind(data[0], $(domNode), name);
                }
            } // End Array
            else {
                // Scalar value
                if (domNode.length > 0) {
                    // If someone needs to bind scalar into multiple elements:
                    for (var i = 0; i < domNode.length; i++)
                        setElementValue(domNode[i], data, name);
                }
                else {
                    setElementValue(domNode, data, name);
                }
            }
        } //function bind() ends

        function init(placeholder) {
            if (placeholder.data("jquery-view-template") != null && placeholder.data("jquery-view-template") != "") {
                var template = placeholder.data("jquery-view-template");
                placeholder.html(template);
            } else {
                var template = placeholder.html()
                placeholder.data("jquery-view-template", template);
            }
        }

        var defaults = {
            onLoading: jQuery.noop,
            onLoaded: jQuery.noop
        };

        properties = $.extend(defaults, options);

        return this.each(function () {

            init($(this));
            properties.onLoading();
            bind(obj, this);
            properties.onLoaded();

        });
    };
})(jQuery);