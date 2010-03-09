package {
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import RayEvent;
	import flash.geom.Rectangle;

	public class VolumeSlider extends MovieClip {
		
		var bar_width:Number;
		var cursor_init_x:Number;
		var cursorBounds:Rectangle;
		var isDragging:Boolean = false;
		var percent:Number = 100;
		
		public function VolumeSlider() {
			bar_width = mask_rect.width;
			cursor_init_x = cursor.x;
			reset();
			this.useHandCursor = true;
			this.buttonMode = true;
			
			cursor.addEventListener(MouseEvent.MOUSE_DOWN, dragCursor);
			stage.addEventListener(MouseEvent.MOUSE_UP, releaseCursor);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackCursorPosition);
			
			cursorBounds = new Rectangle(cursor.width / 2 - 1, cursor.y, cursor.x - 5, 0);
		}
		
		private function dragCursor(e:Event):void {
			isDragging = true;
			cursor.startDrag(true, cursorBounds);
		}
		
		private function releaseCursor(e:MouseEvent):void {
			if(isDragging) {
				cursor.stopDrag();
				isDragging = false;
				
				e.localX = getLocalX();
				dispatchPercent(e);
			} else {
				var p = e.target;
				while(p != null) {
					if(p == this) {
						clickHandler(e);
					}
					p = p.parent;
				}
			}
		}
		
		private function trackCursorPosition(e:MouseEvent):void {
			if(isDragging) {
				mask_rect.width = cursor.x;
				
				e.localX = getLocalX();
				dispatchPercent(e);
			}
		}
		
		public function getLocalX():Number {
			return (((cursor.x - (cursor.width / 2)) / (bar_width - (cursor.width / 2) - 4)) * bar_width);
		}
		
		public function reset() {
			cursor.x = cursor_init_x;
			mask_rect.width = bar_width;
		}
		
		public function dispatchPercent(e:MouseEvent) {
			var pct = (e.localX / this.bar_width) * 100;
			if(pct < 1) {
				pct = 0;
			}
			percent = Math.min(pct, 100);
			dispatchEvent(new RayEvent(pct));
		}
		
		public function clickHandler(e:MouseEvent) {
			dispatchPercent(e);
			setPercentage(percent);
		}
		
		public function setPercentage(percent:Number) {
			cursor.alpha = 1;
			if(!isDragging) {
				var dist = bar_width * (percent / 100);
				mask_rect.width = dist;

				var cursor_dist = (bar_width + 3 - cursor.width) * (percent / 100);
				cursor.x = cursor_dist + (cursor.width / 2);
			}
		}
		public function moveListener(e:Event) {
			var percent = (cursor.x / bar_width) * 100;
			dispatchEvent(new RayEvent(percent));
		}
	}
}