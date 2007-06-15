/** 
 * Drag en Drop (for tags) using scriptaculous sortables.
 * http://wiki.script.aculo.us/scriptaculous/show/Sortable.create
 *
 */

	Event.observe(window, 'load', bagel_tagDrag, false);
	
	// create the sortables and initialize some stuff
	var lastElement;
	var newElement;
	function bagel_tagDrag(reinit) {
		if(!$('dragdropContainer')) return false;
		if(!$('tagList')) return false;
		if(!$('droplist')) return false;
		
		if(reinit == true) {
			Sortable.destroy('tagList');
			Sortable.destroy('droplist');	
		}
		
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
				bagel_removeSubTag();
				bagel_subTagSerialize();
				bagel_popupSubTag();
			}
		});

		bagel_subTagSerialize(); // initialize hidden field tags (when editing)
		
		// check if tag has subtag add
		$$('div.smallPopup').each(function(p) { 
			p.up('div').addClassName('hasSubTag');
		});
		
	}
	
	function bagel_removeSubTag() {
		if(lastElement.up('div').getAttribute('id') == "tagList" && lastElement.hasClassName("isSubTag")) {
			new Effect.Fade(lastElement, { duration: 0.5, afterFinish: function() { lastElement.remove(); } });
		}
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
					$('tagList').insertBefore(lastElement, $('tagList').firstDescendant());
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
					// an item was selected, create a new element and populate it with the
					// proper information
					var dontCreate;
					if(optsNew[n].innerHTML != "") {
						$$('.isSubTag').each(function(tags) { 
							if(tags.getAttribute('id') == "tag_string_" + optsNew[n].value) {
								alert('This tag is allready selected.');
								dontCreate = true;
							}
						});
						if(!dontCreate) {
							var newElement = document.createElement('div');
							var tagDesc = document.createElement('span');
							$(newElement).addClassName('isSubTag');
							$(tagDesc).update(optsNew[n].innerHTML.truncate(13,".."));
							newElement.appendChild(tagDesc);
							$('droplist').appendChild(newElement);
							newElement.setAttribute("id", "tag_string_" + optsNew[n].value);
						}
					}
				}
			}
			// and now revert the original (root) element back!
			$('tagList').insertBefore(lastElement, $('tagList').firstDescendant());
			// reinitialize the draggables
			bagel_tagDrag(true);
		}
		
		// set hidden field
		if($('tags')) {
			// sequence() returns a comma separated list of selected tagIds
			$('tags').value = Sortable.sequence('droplist');
		}
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
	
