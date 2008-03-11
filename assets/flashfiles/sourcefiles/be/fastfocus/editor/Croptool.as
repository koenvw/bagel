package be.fastfocus.editor {	
	
	import flash.display.*;
	import flash.events.*;
    import flash.geom.Rectangle;
    import flash.display.Sprite;
    import flash.display.Shape;
	 
	public class Croptool {

		public var documentroot;
		public var croppingmask:Shape;
		public var iscropped:Boolean = false;
			
		public function Croptool(documentroot){
			super();
			this.documentroot = documentroot;
			croppingmask = new Shape();
			documentroot.contentarea.addChild(croppingmask);
		}
		
		public function crop(){
			iscropped = true;
			documentroot.lastaction = "crop";
			documentroot.activeimage.mask = undefined;
			croppingmask.graphics.clear();
			croppingmask.graphics.beginFill(0xFFFFFF);
			croppingmask.graphics.drawRect(documentroot.selectiontool.p1.x,documentroot.selectiontool.p1.y,documentroot.selectiontool.rect.width,documentroot.selectiontool.rect.height);
			croppingmask.x = documentroot.activeimage.x;
			croppingmask.y = documentroot.activeimage.y;
			documentroot.activeimage.mask = croppingmask;
		}
		
		public function undo() : void {
			documentroot.activeimage.mask = undefined;
			croppingmask.graphics.clear();
			iscropped = false;
		}
		
	}
	
	
}
