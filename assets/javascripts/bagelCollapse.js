
/** collapse menu's **/

	Event.observe(window, 'load', makeColapseMenus, false);
	function makeColapseMenus()
	{
		if(!$$('a.openClose')) return false;
		$$('a.openClose').each(function(bu) {
			if(typeof bu.next('.collapsed') == "object") {
				Element.setStyle(bu, { cursor: 'pointer' });
				Event.observe(bu, 'click', function(event) {
					makeColapseMenusCheck(Event.element(event));
					Event.stop(event);
				}, false);
			}
		});
	}
	
	function makeColapseMenusCheck(element, onlyOpen)
	{
		if(typeof element != "object") return false;
		var e = element;
		clickelement = e.next('.collapsed');
		if(clickelement.visible() && onlyOpen != true) {
			(typeof clickelement.previous('input#relationDisplayState') == "object" ? $('relationDisplayState').value = 0 : "");
			(typeof clickelement.previous('input#websiteDisplayState') == "object" ? $('websiteDisplayState').value = 0 : "");
			(typeof clickelement.previous('input#tagDisplayState') == "object" ? $('tagDisplayState').value = 0 : "");
			e.removeClassName("closed"); 
			e.next('.collapsed').hide();
		}
		else {
			(typeof clickelement.previous('input#relationDisplayState') == "object" ? $('relationDisplayState').value = 1 : "");
			(typeof clickelement.previous('input#websiteDisplayState') == "object" ? $('websiteDisplayState').value = 1 : "");
			(typeof clickelement.previous('input#tagDisplayState') == "object" ? $('tagDisplayState').value = 1 : "");
			e.addClassName("closed");
			e.next('.collapsed').show();
		}
	}
	
