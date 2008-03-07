package be.fastfocus.editor {	
	
	
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.display.*;
	import flash.events.*;
	 
	public class Imageholder extends MovieClip {


		
		public var imageid
		public var filename:String;
		public var preloader;
		public var documentroot;
		
		
		public var originalw:Number;
		public var originalh:Number;

		
			
		public function Imageholder(imageid){
			super();
			this.imageid = imageid;
		}
				
		public function loadImage(filename:String){
			documentroot = root as MovieClip;
			this.filename = filename;
			preloader = documentroot.messagebox.graph.preloader;
			documentroot.messagebox.graph.message.text = documentroot.flashmessage;
			documentroot.messagebox.gotoAndPlay("show");
			documentroot.setChildIndex(documentroot.messagebox,documentroot.numChildren-1);
			
			var imgloader = new Loader();
			var req = new URLRequest(filename+'?n='+Math.random());
			imgloader.contentLoaderInfo.addEventListener(Event.COMPLETE,onComplete);
			imgloader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			imgloader.load(req);
			addChild(imgloader);
		}
		
		public function onComplete(e) : void {
			documentroot.toolbar.resize_tool.slider.x = 75;
			preloader.visible = false;
			var imgloader = e.target.loader;
			originalw = imgloader.width;
			originalh = imgloader.height;
			//originalimage = imgloader.content;
			centerImage();
			documentroot.updateContentarea();
			documentroot.messagebox.gotoAndPlay("hide");
		}
		
		function progressHandler(event:ProgressEvent):void {
			var bl:int= event.bytesLoaded;
			var bt:int = event.bytesTotal;
			var percentLoaded:int = Math.floor((bl / bt) * 100);
			preloader.bar.width = (610 * percentLoaded)/100;
		}
		
		public function centerImage(){
			x = 50;
			y = 50;
		}

		

		
	}
	
	
}
