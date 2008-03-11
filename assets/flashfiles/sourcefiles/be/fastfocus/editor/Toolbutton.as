package be.fastfocus.editor {	
	 
	import flash.display.*;
	import flash.events.MouseEvent;
	
	public class Toolbutton extends MovieClip {

		public var documentroot;
		public var active:Boolean = false;
		public var tooltype:String;
		
		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
			
		public function Toolbutton (tooltype){
			super();
			this.tooltype = tooltype;
			gotoAndStop(tooltype);
			addEventListener(MouseEvent.MOUSE_DOWN,activate);
		}
		
		
		public function activate(e){
			documentroot = root as MovieClip;
			if(active == false){
				this.bg.gotoAndStop("on");
				active = true;
			}
			else{
				this.bg.gotoAndStop("off");
				active = false;	
			}
			if(tooltype=='selectiontool'){
				if(active == true){
					documentroot.selectiontool.activateTool();
				}
				else{
					documentroot.selectiontool.deactivateTool();
				}	
			}
			if(tooltype=='croptool'){
				documentroot.croptool.crop();
				this.bg.gotoAndStop("off");
				if(documentroot.toolbar.selectiontool.active){
					documentroot.selectiontool.deactivateTool();
					documentroot.toolbar.selectiontool.active = false;
					documentroot.toolbar.selectiontool.bg.gotoAndStop("off");
				}
			}
			if(tooltype == 'undotool'){
				documentroot.undo();
				this.bg.gotoAndStop("off");
			}
			
			
		}
		
		
	}
	
	
}
