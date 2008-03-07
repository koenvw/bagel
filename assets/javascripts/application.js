
	function launchImageEditor(id,filename) {
		height = '800';
		width = '1000';
		newwindow=window.open('/plugin_assets/bagel/flashfiles/imageEditor.html?id='+id+'&file='+filename,'imageEditor :: '+filename,'height='+height+',width='+width);
		if (window.focus) {newwindow.focus()}
		return false;
	}


	/* simple function to send messages to the notice flashbox */
	function flashNotice(msg) {
		$('flashNotice').innerHTML = msg;
		new Effect.Appear($('flashNotice'));
	}

	Event.observe(window, 'load', categoriesTree, false);
	function categoriesTree() {
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

	function SelectAllCheckboxes(spanChk) {
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
	function tableHover() {
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
	function filterContentMenu() {
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
	function filterContentMenu_Fade(inputElement, classElement) {
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
	
/** Image revisions */

	Event.observe(window, 'load', getImageRevisions, false);
	function getImageRevisions() {
		if(!$$('ul.imageRevisions') || !$$('div.imgContainer')) return false;
		$$('ul.imageRevisions li a, div.imgContainer a.showpic').each(function(imgsrc) { 
			imgsrc.onclick = function() {
				imgCode = '<div class="imageBlock"><img src="'+ imgsrc +'" /><a href="#" onclick="imgOverlay.destroy(); return false;">close</a></div>';
				imgOverlay = new BagelOverlay();
				imgOverlay.popup(imgCode);
				return false;
			}
		});
	}
	
/** Save generator with ajax and put event listener (ctrl + s) on it **/

	Event.observe(window, 'load', saveGenerator, false);
	function saveGenerator() {
		if(!$("generator-form")) return false;
		Event.observe(document, 'keypress', function(e) {
			if(e.ctrlKey && (e.which == 115 || e.keyCode == 83)) {
				if(typeof codepress1 != "undefined")
					$('generator_template').value = codepress1.getCode();
				else
					return alert("Codepress object not defined"); false;
				new Ajax.Request($("generator-form").getAttribute("action"), { 
					method: "post",
					parameters: $("generator-form").serialize(),
					onCreate: function(l) { 
						saveGen = new BagelOverlay(true);
						saveGen.popup('<div class="savePopup"><h1>Saving Generator...</h1><div class="spinner"></div></div>', 310, 125);
					},
					onComplete: function(o) { 
						saveGen.destroy();
					}
				});
				Event.stop(e);
			}
		}, false);
	}

/** bagel_googleMap, used in FormDefinitions **/

	Event.observe(window, 'load', bagel_googleMap, false);
	function bagel_googleMap() {
		if (typeof GBrowserIsCompatible != "undefined" && GBrowserIsCompatible()) {
			var map = new GMap2(document.getElementById("map"));
			map.addControl(new GLargeMapControl());
			map.addControl(new GMapTypeControl());
			map.setCenter(new GLatLng(50.84323737103243, 4.36981201171875), 7);
			GEvent.addListener(map, "click", function(overlay, point) {
				if (overlay) {
					map.removeOverlay(overlay);
				} else {
					map.clearOverlays();
					map.addOverlay(new GMarker(point));
					$("form_latitude").value = point.lat();
					$("form_longitude").value = point.lng();
				}
			});
			if (!isNaN(parseFloat($("form_latitude").value)) &&
				!isNaN(parseFloat($("form_longitude").value))) {
				var point = new GLatLng(parseFloat($("form_latitude").value),
										parseFloat($("form_longitude").value));
				map.clearOverlays();
				map.addOverlay(new GMarker(point));
			}
		}
	}
