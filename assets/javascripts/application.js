
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

	Event.observe(window, 'load', categoriesTree, false);
	function categoriesTree()
	{
		if ($('categories_tree') != undefined)
		{
			treeObj = new JSDragDropTree();
			treeObj.setTreeId('categories_tree');
			treeObj.setMaximumDepth(7);
			treeObj.setMessageMaximumDepthReached('Maximum depth reached'); // If you want to show a message when maximum depth is reached, i.e. on drop.
			treeObj.imageFolder = "/plugin_assets/bagel/images/dhtml_tree/";
			treeObj.initTree();
			treeObj.expandAll();
		}
	}

	function SelectAllCheckboxes(spanChk)
	{
		var xState=1;
		var theBox=spanChk;
		var str = "";
		elm=document.getElementsByTagName('form')[0].elements;
		for(i=0;i<elm.length;i++) {
			if(elm[i].type=="checkbox" && elm[i].id!=theBox.id) {
		  		if(elm[i].checked!=theBox.checked)
					elm[i].click();
			}
		}
	}

/**
 * Mouseover for table rows.
 * We don't use pure css because IE doens't support :hover on non link elements
 */

	Event.observe(window, 'load', tableHover, false);
	function tableHover()
	{
		var table = $$('table.uniTable');
		for(var i=0; i < table.length; i++) {
			var row = table[i].getElementsByTagName('tr');
			for(var c=0; c < row.length; c++) {
				if(Element.hasClassName(row[c], 'content'))
				{
					row[c].onmouseover = function() { this.style.background = "#eeeeee"; }
					row[c].onmouseout = function() { this.style.background = "#ffffff"; }
				}
			}
		}
	}


/** Content Menu filtering system */

	Event.observe(window, 'load', filterContentMenu, false);
	function filterContentMenu()
	{
		if(!$('leftRightContent')) return false;
		
		// filter field action
		if(!$('filterContent')) return false;
		$('filterContent').focus();
		$('filterContent').onchange = function() {	
			foundclasses = $('leftRightContent').getElementsByClassName('loopme');
			filterContentMenu_Fade(this, foundclasses);
		}
		
		// filter button action
		if(!$('filterContentBtn')) return false;
		$('filterContentBtn').onclick = function() {
			foundclasses = $('leftRightContent').getElementsByClassName('loopme');
			filterContentMenu_Fade($('filterContent'), foundclasses);
			return false;
		}
		
		Event.observe($('filterContent'), 'KEY_RETURN', function(e) { 
			foundclasses = $('leftRightContent').getElementsByClassName('loopme');
			filterContentMenu_Fade($('filterContent'), foundclasses);		
		});
	}
	
	// actual filter/effect action
	function filterContentMenu_Fade(inputElement, classElement)
	{
		for(i = 0; i < classElement.length; i++) {
			// get all h3 elements
			h3strings = classElement[i].getElementsByTagName('h3');
			for(h = 0; h < h3strings.length; h++) {
				if(h3strings[h].innerHTML.toLowerCase().match($F(inputElement).toLowerCase().strip())) {
					new Effect.Fade(classElement[i], { duration: 0.5, from: 0.3, to: 1.0});
				}
				else {
					new Effect.Fade(classElement[i], { duration: 0.5, from: 1.0, to: 0.3});
				}
			}
		}
	}
	
/** Relations functions **/

	Event.observe(window, 'load', bagel_addRelation, false);
	function bagel_addRelation()
	{
		if(!$$('.relationManager')) return false;
		$$('.relationManager').each(function(relationManager) { 
			relationManager.getElementsByClassName('addRelation').each(function(a) { 
				a.onclick = function() {
					makeColapseMenusCheck(a.up('div',1).down('a.openClose'), true);
					relContent = a.next('.bagelRelationContent');
					relOverlay = new BagelOverlay();
					relOverlay.setRestoreObj(relContent.up(0));
					relOverlay.popup(relContent, 450, 281);
					relContent.show();
					relClosebuttons = relContent.getElementsByClassName('close');
					for(c = 0; c < relClosebuttons.length; c++) {
						relClosebuttons[c].onclick = function() { relOverlay.destroy(); return false; }
					}
					
					// populate the link actions inside the popup					
					return false;
				}
			});
		});
	}
	
	function relVisualAction()
	{
		// check relation list and apply some stuff to it
		if(!$$('.relationManager')) return false;
		var lists = $$('ul#relations_sorted_inlist li');	
		if(lists.length > '1') lists[0].hide();
		else lists[0].show(); 
			
		$$('ul#relations_sorted_inlist li a[class="delete"]').each(function(delbut) { 
			Event.observe(delbut, 'click', function() {
				var lists = $$('ul#relations_sorted_inlist li');
				(lists.length == '1' ? lists[0].show() : '');
			}, false);
		});
		
		// destroy current overlay
		if(typeof relOverlay == "object") {	
			relOverlay.destroy();
		}
	}
	
/** Image revisions */

	Event.observe(window, 'load', getImageRevisions, false);
	function getImageRevisions()
	{
		if(!$$('ul.imageRevisions')) return false;
		$$('ul.imageRevisions li a').each(function(imgsrc) { 
			imgsrc.onclick = function() {
				imgCode = '<div class="imageBlock"><img src="'+ imgsrc +'" /><a href="#" onclick="imgOverlay.destroy(); return false;">close</a></div>';
				imgOverlay = new BagelOverlay();
				imgOverlay.popup(imgCode);
				return false;
			}
		});
	}
