/** 
 * Drag en Drop (for tags) using scriptaculous sortables.
 * http://wiki.script.aculo.us/scriptaculous/show/Sortable.create
 *
 */

	Event.observe(window, 'load', bagel_tagDrag, false);
	
	// create the sortables and initialize some stuff
	var lastElement;
	function bagel_tagDrag() {		
		if(!$('dragdropContainer')) return false;
		if(!$('tagList')) return false;
		if(!$('droplist')) return false;
		
		Sortable.create($('tagList'), { 
			dropOnEmpty: true,
			constraint: false,
			containment: ['tagList','droplist'],
			ghosting: true,
			tag: 'div'
		});
		Sortable.create($('droplist'), { 
			dropOnEmpty:true,
			constraint: false,
			containment: ['tagList','droplist'],
			ghosting: true,
			tag: 'div',
			// workaround to set last selected element
			onChange: function(element) { 
				lastElement = element;
			},
			onUpdate: function(event) {
				bagel_subTagSerialize();
				bagel_popupSubTag();
				bagel_makeClickable();
			}
		});

		bagel_subTagSerialize(); // initialize hidden field tags (when editing)
		bagel_makeClickable(); // make subtags clickable
		
		// check if tag has subtag add
		$$('div.smallPopup').each(function(p) { 
			p.up('div').addClassName('hasSubTag');
		});
		
	}

	// popup the subtag window
	function bagel_popupSubTag(myLastElement) {
		if(typeof myLastElement == "object") lastElement = myLastElement;
		if(!lastElement || typeof lastElement != "object") return false;
		var subTagElement = lastElement.getElementsByClassName('smallPopup')[0];
		if(typeof subTagElement == "object" && lastElement.up('div').getAttribute('id') == "droplist") {
			
			myOverlay = new BagelOverlay();
			myOverlay.setRestoreObj(lastElement);
			myOverlay.popup(subTagElement, 400, 125);
			subTagElement.show();

			// some close actions
			closebuttons = subTagElement.getElementsByClassName('close');
			for(c = 0; c < closebuttons.length; c++) {
				closebuttons[c].onclick = function() {
					myOverlay.destroy();
					return false;
				}
			}
			
			// save action
			$$('input.save').each(function(sb) { 
				sb.onclick = function() {
					bagel_subTagSerialize(this);
					myOverlay.destroy();
				}
			});
		}
	}
	
	// create serialize string
	function bagel_subTagSerialize(object) {
		// get current option
		if(typeof object == "object") {
			optsNew = object.up('.subTag').down('.subtagSelect').getElementsByTagName('option');
			for(n = 0; n < optsNew.length; n++) {
				if(optsNew[n].selected) {
					// an item was selected we update the "container"-tag with the name and id
					if(optsNew[n].innerHTML != "")
						lastElement.update(optsNew[n].innerHTML.truncate(9));
						
					lastElement.id = "string_" + optsNew[n].value;
				}
			}
		}
		
		// set hidden field
		if($('tags')) {
			// sequence() returns a comma separated list of selected tagIds
			$('tags').value = Sortable.sequence('droplist');
		}
	}
	
	// make elements with subtags clickable
	function bagel_makeClickable(event) {
		$$('div#droplist div').each(function(e) {
			Event.observe(e, 'click', function() {
				if(typeof e.getElementsByClassName('smallPopup')[0] == "object") {
					bagel_popupSubTag(e);
				}
			}, true);
		});
	}
	
	// create new tag
	Event.observe(window, 'load', bagel_newTag, false);
	function bagel_newTag() {
		if(typeof $$('a.addTag')[0] == "object") {
			Event.observe($$('a.addTag')[0], 'click', function(event) {
				element = Event.element(event);
				makeColapseMenusCheck(element.previous('.openClose'), true);
				addTagElement = element.next('.addTagField');
				restoreElement = element.up('.subContent');
				addTagOverlay = new BagelOverlay();
				addTagOverlay.setRestoreObj(restoreElement);
				addTagOverlay.popup(addTagElement, 320, 125);
				addTagElement.show();
				Event.stop(event);
			}, false);
			Event.observe($$('.addTagField a.close')[0], 'click', function(e) { addTagOverlay.destroy(); Event.stop(e); }, false);
			Event.observe($('tag_add_submit'), 'click', function(e) {
				new Ajax.Request('/admin/tags/add_tag', {
					parameters: { new_tag: $F('tag_new_tag'), child_of: $F('tag_child_of') },
					onComplete: function(t) {
						bagel_tagDrag(); 					
						addTagOverlay.destroy();
					}
				});
			}, false);
		}
		else return false
	}
	