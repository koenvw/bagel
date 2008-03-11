package be.fastfocus.editor {	
	 
	import flash.display.*;
	import flash.events.*;
    import flash.geom.Rectangle;
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.geom.Matrix;

	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;

	
	
	public class Selectiontool  {

		public var documentroot;
		public var canvas:Sprite;
		public var orig_x;
		public var orig_y;
		public var p1,p2,p3,p4;
		public var rect;

		
			
		public function Selectiontool(documentroot){
			super();
			this.documentroot = documentroot as MovieClip;
			canvas = new Sprite();
			documentroot.addChild(canvas);
		}
		
		public function activateTool(){
			documentroot.addEventListener(MouseEvent.MOUSE_DOWN,activateDrawing);
			canvas.graphics.clear();
			documentroot.selectioncursor.addEventListener(Event.ENTER_FRAME, customCursor);
			documentroot.setChildIndex(documentroot.selectioncursor,documentroot.numChildren -1);
		}
		
		public function deactivateTool() : void {
			documentroot.removeEventListener(MouseEvent.MOUSE_DOWN,activateDrawing);
			canvas.graphics.clear();
			Mouse.show();
			documentroot.selectioncursor.x = -300;
			documentroot.selectioncursor.removeEventListener(Event.ENTER_FRAME, customCursor);
		}
		
		
		

		function customCursor(Event){
			Mouse.hide();
			documentroot.selectioncursor.x = documentroot.mouseX;
			documentroot.selectioncursor.y = documentroot.mouseY;
		}




		
		public function activateDrawing(e){
			//documentroot.removeEventListener(MouseEvent.MOUSE_DOWN,activateDrawing);
			documentroot.addEventListener(MouseEvent.MOUSE_UP,stopDrawing);
			documentroot.addEventListener(MouseEvent.MOUSE_MOVE,drawCanvas);
			canvas.graphics.clear();
		    this.orig_x = documentroot.mouseX;
		    this.orig_y = documentroot.mouseY;
		
		
		}
		
		public function drawCanvas(e){
			canvas.graphics.clear();
	        canvas.graphics.lineStyle(1, 0xFF0000, 100);
	        canvas.graphics.moveTo(this.orig_x, this.orig_y);
	        canvas.graphics.lineTo(documentroot.mouseX, this.orig_y);
	        canvas.graphics.lineTo(documentroot.mouseX, documentroot.mouseY);
	        canvas.graphics.lineTo(this.orig_x, documentroot.mouseY);
	        canvas.graphics.lineTo(this.orig_x, this.orig_y);
			e.updateAfterEvent();
		}
		
		public function stopDrawing(e){
			documentroot.removeEventListener(MouseEvent.MOUSE_UP,stopDrawing);
			documentroot.removeEventListener(MouseEvent.MOUSE_MOVE,drawCanvas);
			getCoordsOnImage();
		}
		
		public function getCoordsOnImage(){
			var offsetx = documentroot.activeimage.x;
			var offsety = documentroot.activeimage.y;
			
			rect = canvas.getRect(documentroot.activeimage);
			//rect.x -= offsetx;
			//rect.y -= offsety;
			
			p1 = {x:rect.x,y:rect.y};
			p2 = {x:rect.x+rect.width ,y:rect.y};
			p3 = {x:p2.x,y:rect.y+rect.height};
			p4 = {x:p1.x,y:p3.y};
		
		}
		
		
	}
	
}
