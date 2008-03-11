package be.fastfocus.editor {	
	 
	
    import fl.containers.ScrollPane;
    import fl.events.ScrollEvent;
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.display.*;
	import flash.events.*;
	import flash.display.Shape;
    import flash.net.*;



	public class Main extends MovieClip {
		
		//public var imageholder:Imageholder
		public var images:Array;
		public var activeimage;
		public var contentarea;
		public var sp:ScrollPane;
		public var lrdot:MovieClip;
		public var flashVars;
		public var posturl:String = '/admin/media_items/update_edited_image'
		public var flashmessage:String;
		public var selectiontool;
		public var croptool;
		public var lastaction:String;


		//--------------------------------------
		//  CONSTRUCTOR
		//--------------------------------------
		
		public function Main() {
			super();
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, stageResizeHandler);
			images = [];
			init();
		}
		
		public function init(){
			bg.width = stage.stageWidth + 400;
			bg.height = stage.stageHeight + 400;
			createScrollPane();
			getParams();
			flashmessage = "Loading image...";
			openImage(flashVars['file'],flashVars['id']);
			//openImage("woman.jpg","2");
			selectiontool = new Selectiontool(this);
			croptool = new Croptool(this);
			toolbar.init();
		}
		
		
		public function getParams() : void {
			flashVars = loaderInfo.parameters;
		}
		
		public function stageResizeHandler(e:Event):void{
			toolbar.reposition();
		}
		
		public function openImage(filename:String,imageid){
			var imageholder = new Imageholder(imageid);
			activeimage = imageholder;
			contentarea.addChild(imageholder);
			imageholder.loadImage(filename);
			images.push(imageholder);
		}
		
		
		public function reloadImage(imageholder){
			for(var i:Number = 0; i<images.length;i++){
				if(images[i]==imageholder){
					openImage(imageholder.filename,imageholder.imageid);
					contentarea.removeChild(imageholder);
					images.splice(i,1);
				}
			}
		}
		
		
		public function updateContentarea(){
			lrdot.x = activeimage.x + activeimage.width + 100;
			lrdot.y = activeimage.y + activeimage.height + 100;
			sp.update();
		}
		
        private function createScrollPane():void {
            sp = new ScrollPane();
            sp.move(0,40);
            sp.setSize(stage.stageWidth,stage.stageHeight - 40);
            sp.source = new MovieClip;
			contentarea = sp.content;
			lrdot = new MovieClip;
			lrdot.alpha = 0;
			doDrawRoundRect(lrdot)
			contentarea.addChild(lrdot);
            sp.scrollDrag = true;
            addChild(sp);         
        }

		public function undo(){
			if(lastaction == 'resize'){
				toolbar.resize_tool.undo();
			}
			if(lastaction == 'crop'){
				croptool.undo();
			}
		}


        private function doDrawRoundRect(targetmc):void {
            var child:Shape = new Shape();
            child.graphics.beginFill(0xFFCC00);
            child.graphics.lineStyle(1, 0x666666);
            child.graphics.drawRoundRect(0, 0, 10, 10, 1);
            child.graphics.endFill();
            targetmc.addChild(child);
        }
		
		
		public function saveResult(e) : void {
			var url:String = posturl ;
            var variables:URLVariables = new URLVariables();
            //resizing vars
			variables.newwidth = activeimage.width;
			variables.newheight = activeimage.height;
			//cropping vars
			if(croptool.iscropped){
				variables.crop_x = selectiontool.p1.x;
				variables.crop_y = selectiontool.p1.y;
				variables.crop_width = selectiontool.p3.x;
				variables.crop_height = selectiontool.p3.y; 
				croptool.iscropped = false;
			}
			
			variables.id = activeimage.imageid;
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
            var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.GET;
			request.data = variables;
            loader.load(request);
		}
		

        private function loaderCompleteHandler(e):void {
			flashmessage = "Your image has been updated successfully... reloading image";
			setChildIndex(messagebox,this.numChildren-1);
			messagebox.graph.message.text = flashmessage;
			messagebox.gotoAndPlay('show');
			reloadImage(activeimage);
        }
		
		
	}

	
}