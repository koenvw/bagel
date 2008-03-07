package be.fastfocus.editor {	
	 
	import flash.display.MovieClip;
	import flash.display.*;
	import flash.events.*;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
	
	public class Resizetool extends MovieClip {

		public var slider:MovieClip;
		public var documentroot:MovieClip;
		public var bar:MovieClip;
		public var dragconstraints:Rectangle;
		
			
		public function Resizetool(){
			super();
			documentroot = root as MovieClip;
			
			bar = resize_bar;
			slider = bar.slider;
			slider.buttonMode = true;
			slider.useHandCursor = true;
			dragconstraints = new Rectangle(0,slider.y,150,0);
			slider.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		}
		
		
		function mouseDown(event:MouseEvent):void {
		    slider.startDrag(true,dragconstraints);
			slider.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseReleased);
			this.addEventListener(Event.ENTER_FRAME,trackScaling );
		}

		function mouseReleased(event:MouseEvent):void {
		    slider.stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseReleased);
			slider.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			this.removeEventListener(Event.ENTER_FRAME,trackScaling );
		}
		
		
		public function trackScaling(e){
			var absvalue = 0;
			if(slider.x > 75){
				absvalue = slider.x - 75;
				var pct = (absvalue * 75) / 100 
			}
			else if(slider.x < 75){
				absvalue = (slider.x - 75)*-1 ;
				var pct = (absvalue * 75) / 100 
			}
			if(slider.x > 75){
				documentroot.activeimage.width = documentroot.activeimage.originalw + ((documentroot.activeimage.originalw * pct) /100)*2;
				documentroot.activeimage.height = documentroot.activeimage.originalh + ((documentroot.activeimage.originalh * pct) /100)*2;
			}
			else if(slider.x < 75){
				documentroot.activeimage.width = documentroot.activeimage.originalw - ((documentroot.activeimage.originalw * pct) /100)*2;
				documentroot.activeimage.height = documentroot.activeimage.originalh - ((documentroot.activeimage.originalh * pct) /100)*2;
			}
			documentroot.updateContentarea();
			
		}
		
		
	}
	
	
}
