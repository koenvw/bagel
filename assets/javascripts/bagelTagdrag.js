/** 
 * Drag en Drop (for tags) using scriptaculous sortables.
 * http://wiki.script.aculo.us/scriptaculous/show/Sortable.create
 *
 */

	Event.observe(window, 'load', bagelTag_tag_init, false);
	
	// create the sortables and initialize some stuff
	var lastElement;
	function bagelTag_tag_init() {		
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
				bagelTag_subTagSerialize();
				bagelTag_popupSubTag();
				bagelTag_check_if_exists();
			}
		});

		bagelTag_subTagSerialize(); // initialize hidden field tags (when editing)
		
		// check if tag has subtag and out style on it
		$$('div.smallPopup').each(function(p) { 
			p.up('div').addClassName('hasSubTag');
		});
	}
	
	function bagelTag_check_if_exists() {
		if(lastElement.up('div').getAttribute('id') == "tagList") {
			if(lastElement.hasClassName('isSubTag')) {
				lastElement.remove();
			}
		}
	}
	
	// clone the lastElement and place it back in the tagList
	function bagelTag_cloneElement(restore) {
		clonedElement = Object.clone(lastElement);
		if(restore == true) {
			new Insertion.Bottom('tagList', '<div>'+ clonedElement.innerHTML +'</div>');
			bagelTag_reInitialize_sortables();
		}
		return clonedElement;
	}
	
	// destroy all sortables and recall the main init function
	function bagelTag_reInitialize_sortables() {
		Sortable.destroy('tagList');
		Sortable.destroy('droplist');
		bagelTag_tag_init();
	}

	// popup the subtag window
	function bagelTag_popupSubTag(myLastElement) {
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
					bagelTag_cloneElement(true);
					lastElement.remove();
					return false;
				}
			}
			
			// save action
			$$('input.save').each(function(sb) { 
				sb.onclick = function() {
					bagelTag_subTagSerialize(this);
					myOverlay.destroy();
					// check if value isn't empty.. restore on true
					var options = lastElement.getElementsByTagName('option');
					for(i = 0; i < options.length; i++) {
						if(options[i].selected) {
							if(options[i].innerHTML == "") {
								lastElement.remove();
							}
						}
					}
					bagelTag_cloneElement(true);
					// allright.. now convert it to a single element
					lastElement.getElementsByClassName('smallPopup')[0].remove();
					lastElement.removeClassName('hasSubTag');
					lastElement.addClassName('isSubTag');
					return false;
				}
			});
		}
	}
	
	// create serialize string
	function bagelTag_subTagSerialize(object) {
		// get current option
		if(typeof object == "object") {
			optsNew = object.up('.subTag').down('.subtagSelect').getElementsByTagName('option');
			for(n = 0; n < optsNew.length; n++) {
				if(optsNew[n].selected) {
					// an item was selected we update the "container"-tag with the name and id
					if(optsNew[n].innerHTML != "")
						lastElement.update('<span class="tagName">'+ optsNew[n].innerHTML.truncate(13,"..") +'</span>');
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
	
	// create new tag
	Event.observe(window, 'load', bagelTag_newTag, false);
	function bagelTag_newTag() {
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
						bagelTag_reInitialize_sortables();					
						addTagOverlay.destroy();
					}
				});
			}, false);
		}
		else return false
	}
	
