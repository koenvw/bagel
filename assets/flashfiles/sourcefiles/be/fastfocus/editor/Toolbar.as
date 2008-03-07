package be.fastfocus.editor {	
	
	
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.display.*;
	import flash.events.*;
	 
	public class Toolbar extends MovieClip {
		
		public var documentroot : MovieClip;
		
		
		public function Toolbar() : void {
			super();
			documentroot = root as MovieClip;
			reposition();
			setButtons();
			
		}
		
		public function setButtons(){
			savebtn.label.text = "save";
			savebtn.addEventListener(MouseEvent.MOUSE_DOWN,documentroot.saveResult);
		}
		
		public function reposition() : void {
			this.background.width = stage.stageWidth + 3;
			this.savebtn.x = stage.stageWidth - savebtn.width - 6;
		}
		

		
		
	}
	
}