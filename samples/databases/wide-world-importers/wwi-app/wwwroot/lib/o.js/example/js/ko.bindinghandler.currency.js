// +++
// knockunt.bindinghandler.js - v0.2a
// This adds new binding-handlers to ko for a currency value (currently supporting dollar and euro)
// Example binding: data-bind="$:Price"
// Complex binding: data-bind="currency:Price,currencyUnit:'AUD',positions:4,digitGroupSeparator:false"
//
// By Jan Hommes
// Date: 09.12.2014
// +++

// +++
// fast binding for dollar
// +++
ko.bindingHandlers.dollar = {
	update: function(element, valueAccessor, allBindingsAccessor) {
		ko.bindingHandlers.currency.update(element, valueAccessor, allBindingsAccessor);
	}
}

// +++
// fast binding for dollar
// +++
ko.bindingHandlers.euro = {
	update: function(element, valueAccessor, allBindingsAccessor) {
		var bindings=ko.utils.unwrapObservable(allBindingsAccessor());
		bindings['digitGroupSeparator']=bindings['digitGroupSeparator'] || 'point';
		bindings['currencyUnit']=bindings['currencyUnit'] || '€';
		ko.bindingHandlers.currency.update(element, valueAccessor, ko.observable(bindings));
	}
}

// +++
// the currency bindinghandler itself
// +++
ko.bindingHandlers.currency = {
	update: function(element, valueAccessor, allBindingsAccessor) {
		//get the defaults
		var value = ko.utils.unwrapObservable(valueAccessor());
		var positions=ko.bindingHandlers.currency.defaultPositions;
		if(typeof allBindingsAccessor().positions!=='undefined') {
			positions=allBindingsAccessor().positions;
			console.log(allBindingsAccessor().positions);
		}
		var currencyUnit=allBindingsAccessor().currencyUnit || ko.bindingHandlers.currency.defaultCurrencyUnit
		var digitGroupSeparator=allBindingsAccessor().digitGroupSeparator || 'comma';
	
	    //format the value
		var formattedValue = parseFloat(value).toFixed(positions);
		if(isNaN(formattedValue))
			formattedValue=0.00.toFixed(positions);
		if(digitGroupSeparator!==false)
			var finalFormatted = ko.bindingHandlers.currency.digitGroupSeparatorFunc[digitGroupSeparator](formattedValue);
		else
			var finalFormatted = formattedValue;
			
		//update the observable
		ko.bindingHandlers.text.update(element, function() { return finalFormatted + " " + currencyUnit; });
	},
	defaultCurrencyUnit:"$",
	defaultPositions: 2,
	digitGroupSeparatorFunc: {
		comma:function(original){
		   original+= '';
			x = original.split('.');
			x1 = x[0];
			x2 = x.length > 1 ? '.' + x[1] : '';
			var rgx = /(\d+)(\d{3})/;
			while (rgx.test(x1)) {
				x1 = x1.replace(rgx, '$1' + ',' + '$2');
			}
			return x1 + x2;		
		},
		point: function(original){
		   original+= '';
			x = original.split('.');
			x1 = x[0];
			x2 = x.length > 1 ? ',' + x[1] : '';
			var rgx = /(\d+)(\d{3})/;
			while (rgx.test(x1)) {
				x1 = x1.replace(rgx, '$1' + '.' + '$2');
			}
			return x1 + x2;		
		}
	}
};
