/**
 *      FILE: bagelOverlay.js Fri Apr 06 12:38:18 CEST 2007
 *
 *      Copyright 2007 dotProjects
 *
 *      This program is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      This program is distributed in the hope that it will be  useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with this program; if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

	// 
	// Position.center(element) - automatically positions an element to the center of the screen.
	// Found this snipplet on the ror mailing list
	//
	Position.center = function(element) {
			var options = Object.extend({
			    zIndex: 1000,
			    update: false
			}, arguments[1] || {});
			element = $(element);
			if(!element._centered) {
			    Element.setStyle(element, {position: 'absolute', zIndex: options.zIndex });
			    element._centered = true;
			}
			var dims = Element.getDimensions(element);
			Position.prepare();
			var winWidth = self.innerWidth || document.documentElement.clientWidth || document.body.clientWidth || 0;
			var winHeight = self.innerHeight || document.documentElement.clientHeight || document.body.clientHeight || 0;
			var offLeft = (Position.deltaX + Math.floor((winWidth-dims.width)/2));
			var offTop = (Position.deltaY + Math.floor((winHeight-dims.height)/2));
			element.style.top = ((offTop != null && offTop > 0) ? offTop : '0') + 'px';
			element.style.left = ((offLeft != null && offLeft > 0) ? offLeft : '0') + 'px';
	}
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////////
	// BagelOverlay class

	var BagelOverlay = Class.create();
	BagelOverlay.prototype = {
		
		initialize: function(nofade) {
			// create document body object (for dimension, etc...)
			this._docBody = document.getElementsByTagName("body")[0];
			// create overlay
			this._nofade = ( nofade == true ? true : false );
			this._createOverlay();
		},
		
		//
		// fill()
		// fill the popup with and object or string 
		// @content (string or object) fills the popup with content or object. If this is an object,
		//                             the object will be moved to the popup element and restored
		//                             on close.
		// @w (int) the width of the popup container (needed for positioning)
		// @h (int) the height of the popup container (needed for positioning)
		//
		popup: function(content, w, h)	{
		
			// set width and height of popup
			if(!w) this._popupWidth = 400;
			else this._popupWidth = w;
			if(!h) this._popupHeight = 200;
			else this._popupHeight = h;
				
			this._content = (typeof content == "undefined" ? "no content set" : content);
			this._createPopup(this._content);
		},
		
		//
		// destroy()
		// destroy the overlay and popup element and restores the content to its former position
		// if a parent object has been set.
		//
		destroy: function() {
			Element.remove(this._overlayPopup);
			if(typeof this._content == "object") {
				this._content.hide();
				if(this._getRestoreElement) {
					this._getRestoreElement().appendChild(this._content);
				}
			}
			new Effect.Fade(this._overlay, {duration: 0.2, afterFinish: function(obj) { 
				Element.remove(obj.element);
			}});
		},

		//
		// setRestoreObj()
		// Set this object if you want to restore the content object on overlay close
		//
		setRestoreObj: function(parent) {
			this._restoreElement = parent;
		},
		
		//
		// _createOverlay()
		//
		_createOverlay: function() {	
			// create overlay element			
			this._overlay = document.createElement("div");
			Element.addClassName(this._overlay, "overlay");
			
			Element.setStyle(this._overlay, { 
				display: 'none',
				zIndex: '999', 
				position: 'absolute',
				left: 0,
				top: 0, 
				height: this._getPageDimensions().height +'px',
				width: this._getPageDimensions().width +'px'
			});
			
			// append to document body
			this._docBody.appendChild(this._overlay);
			
			// fade to screen
			if(this._nofade == false) {
				new Effect.Appear(this._overlay, {from: 0.0, to: 0.6, duration: 0.2 });
			}
			else {
				Element.setOpacity(this._overlay, 0.6);
				this._overlay.show();
			}
		},
		
		//
		// _createPopup()
		//
		_createPopup: function(content)	{
			// create popup element
			this._overlayPopup = document.createElement("div");
			Element.addClassName(this._overlayPopup, "overlay-cont")
			
			// append to document body
			this._docBody.appendChild(this._overlayPopup);
			
			Element.setStyle(this._overlayPopup, {  
				display: 'none',
				height: (this._popupHeight) +'px',
				width: (this._popupWidth) +'px'
			});
			Position.center(this._overlayPopup);
			
			//place content into element
			if(typeof this._content == "object")
				this._overlayPopup.appendChild(this._content);
			else if (typeof this._content == "string")
				new Insertion.Top(this._overlayPopup, this._content);
			else {
				alert('The given content is not an object or a string');
				return false;
			}
			
			// fade to screen
			if(this._nofade == false)
				new Effect.Appear(this._overlayPopup, {from: 0.0, to: 1.0, duration: 0.4, queue: 'end'});
			else 
				this._overlayPopup.show();
			
		},
		
		//
		// getParent Get the parent node of the content element
		// @return object or false
		//
		_getRestoreElement: function() {
			if(typeof this._restoreElement == "object")
				return this._restoreElement;
			else
				return false
		},
		
		//
		// Core code from - quirksmode.org
		// Edit for Firefox by pHaez
		// Cleaned and made this function more "prototype" by J0Sb31R
		//
		_getPageDimensions: function() {
			var docHeight, docWidth, windowHeight;
			
			if (window.innerHeight && window.scrollMaxY)
				pageHeight = window.innerHeight + window.scrollMaxY;
			// all but Explorer Mac
			else if (document.body.scrollHeight > document.body.offsetHeight)
				pageHeight = document.body.scrollHeight;
			// Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
			else
				pageHeight = document.body.offsetHeight;

			// all except Explorer
			if (self.innerHeight)
				windowHeight = self.innerHeight;
			// Explorer 6 Strict Mode
			else if (document.documentElement && document.documentElement.clientHeight)
				windowHeight = document.documentElement.clientHeight;
			// other Explorers
			else if (document.body)
				windowHeight = document.body.clientHeight;

			if(pageHeight < windowHeight)
				docHeight = windowHeight;
			else
				docHeight = pageHeight;
				
			// get body width from prototype
			docWidth = Element.getWidth(this._docBody);
			return {width: docWidth, height: docHeight};
		}
	}