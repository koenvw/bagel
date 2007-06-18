/**
 *	Bagel ration handling
 *  *********
 */

	Event.observe(window, 'load', bagel_addRelation, false);
	function bagel_addRelation()
	{
		if(!$$('.relationManager')) return false;
		$$('.relationManager').each(function(relationManager) { 
			relationManager.getElementsByClassName('addRelation').each(function(a) { 
				Event.observe(a, 'click', function(e) {
					bagel_addRelation_do(Event.element(e));
					Event.stop(e);
				}, false);
			});
		});
		
		// enable usage of random links (outsite the relationManager obj)
		$$('a.subAddRelation').each(function(subrel) {
			Event.observe(subrel, 'click', function(ev) {
				$$('.relationManager a.addRelation').each(function(subrel2) {
					bagel_addRelation_do(subrel2);
				});
				Event.stop(ev);
			}, false);
		});
	}
	
	function bagel_addRelation_do(a)
	{
		makeColapseMenusCheck(a.up('div',1).down('a.openClose'), true);
		relContent = a.next('.bagelRelationContent');
		relOverlay = new BagelOverlay();
		relOverlay.setRestoreObj(relContent.up(0));
		relOverlay.popup(relContent, 450, 281);
		relContent.show();
		relClosebuttons = relContent.getElementsByClassName('close');
		for(c = 0; c < relClosebuttons.length; c++) {
			relClosebuttons[c].onclick = function() { 
				$$('.relationBox option')[0].selected = true;
				relOverlay.destroy();
				return false;
			}
		}
	}
	
	Event.observe(window, 'load', relVisualAction, false);
	function relVisualAction()
	{
		// check relation list and apply some stuff to it
		if(!$$('.relationManager')) return false;
		var lists = $$('ul#relations_sorted_inlist li');	
		if(lists.length > '1') {
			lists[0].hide();
			new Effect.Appear('sortRelations', {duration: '1'});
		}
			
		$$('ul#relations_sorted_inlist li a[class="delete"]').each(function(delbut) { 
			Event.observe(delbut, 'click', function() {
				var lists = $$('ul#relations_sorted_inlist li');
				if(lists.length == '1') {
					lists[0].show();
					$('sortRelations').hide();
				}
			}, false);
		});
		
		// destroy current overlay
		if(typeof relOverlay == "object") {	
			relOverlay.destroy();
		}
		
		// reset relations field
		if($$('.relationBox option')[0])
			$$('.relationBox option')[0].selected = true;
	}
	
	Event.observe(window, 'load', createRelation, false);
	function createRelation()
	{
		$$('a.createRelation').each(function(button) {
			Event.observe(button,'click', function(ev) {
				Event.stop(ev);
				new Ajax.Request(button.getAttribute("href"), {
					onLoading: function() {
						if(typeof relOverlay == "object") {
							relOverlay.destroy();
						}
					},
					onComplete: function(content) {
						relCrOverlay = new BagelOverlay(true);
						relCrOverlay.popup(content.responseText, 830, 480);
					}
				});
			}, false);
		});
	}
	