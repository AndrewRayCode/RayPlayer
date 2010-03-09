package {
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import RayEvent;

	public class SeekBar extends MovieClip {
		
		var bar_width:Number;
		var cursor_init_x:Number;
		var cursorBounds:Rectangle;
		var isDragging:Boolean = false;
		var percent:Number = 100;
		
		public function SeekBar() {
			bar_width = mask_rect.width;
			cursor_init_x = cursor.x;
			reset();
			this.useHandCursor = true;
			this.buttonMode = true;
			cursor.addEventListener(MouseEvent.MOUSE_DOWN, dragCursor);
			stage.addEventListener(MouseEvent.MOUSE_UP, releaseCursor);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, trackCursorPosition);
			
			cursorBounds = new Rectangle(cursor.x, cursor.y + 1, (bar_width - cursor.width) + 5, 0);
		}
		
		private function dragCursor(e:Event):void {
			isDragging = true;
			cursor.startDrag(true, cursorBounds);
		}
		
		private function releaseCursor(e:MouseEvent):void {
			if(isDragging) {
				cursor.stopDrag();
				isDragging = false;
				
				e.localX = (((cursor.x - this.x) / (bar_width + 3 - cursor.width)) * bar_width) - ((cursor.width / 2) - 1);
				clickHandler(e);
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
		
		public function getLocalX():Number {
			return (((cursor.x - (cursor.width / 2)) / (bar_width - (cursor.width / 2) - 4)) * bar_width);
		}
		
		private function trackCursorPosition(e:MouseEvent):void {
			if(isDragging) {
				mask_rect.width = cursor.x;
			}
		}
		
		public function reset() {
			cursor.alpha = 0;
			cursor.x = cursor_init_x;
			mask_rect.width = 0;
			mask_loaded.width = 0;
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
		public function setLoaded(percent:Number) {
			cursor.alpha = 1;
			var dist = bar_width * (percent / 100);
			mask_loaded.width = dist;
		}
	}
}