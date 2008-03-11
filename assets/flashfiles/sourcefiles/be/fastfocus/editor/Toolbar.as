package be.fastfocus.editor {	
	
	
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.display.*;
	import flash.events.*;
	 
	public class Toolbar extends MovieClip {
		
		public var documentroot : MovieClip;
		public var actionbutton_panel:MovieClip;
		public var toolbutton_panel:MovieClip;
		
		public var selectiontool;
		public var croptool;
		public var undotool;
		
		public function Toolbar() : void {
			super();
			documentroot = root as MovieClip;
		}
		
		public function init(){
			createActionButtons();
			createToolButtons();
			reposition();
		}
		
		public function createToolButtons() : void {
			toolbutton_panel = new MovieClip();
			this.addChild(toolbutton_panel);
			
			selectiontool = new Toolbutton("selectiontool");
			toolbutton_panel.addChild(selectiontool);
			
			croptool = new Toolbutton("croptool");
			toolbutton_panel.addChild(croptool);
			croptool.x = selectiontool.x + selectiontool.width + 6;
			
			undotool = new Toolbutton("undotool");
			toolbutton_panel.addChild(undotool);
			undotool.x = croptool.x + croptool.width + 6;
		}
		
		public function createActionButtons(){
			actionbutton_panel = new MovieClip();
			this.addChild(actionbutton_panel);
			var savebtn = new Standardbutton();
			savebtn.name = "savebtn";
			savebtn.label.text = "save";
			savebtn.addEventListener(MouseEvent.MOUSE_DOWN,documentroot.saveResult);
			actionbutton_panel.addChild(savebtn);
		}
		
		public function reposition() : void {
			this.background.width = stage.stageWidth + 3;
			this.actionbutton_panel.x = stage.stageWidth - actionbutton_panel.width - 6;
			this.actionbutton_panel.y = 6;
			this.toolbutton_panel.x = resize_tool.x + resize_tool.width + 12;
			this.toolbutton_panel.y = 4;
		}
		

		
		
	}
	
}