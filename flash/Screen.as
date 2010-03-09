package {
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class Screen extends MovieClip {
		
		private var songTitle:String;
		private var songCategory:String;
		
		public function Screen() {
			this.addEventListener(Event.ENTER_FRAME, frameEventHandler);
			 tf.bold = true;
		}
		public function setTitle(str:String) {
			songTitle = str;
		}
		public function setCategory(str:String) {
			this.category.text = str;
		}
		public function setTime(ms:Number) {
			this.time.text = formatTime(ms);
		}
		
		public function setTotal(ms:Number) {
			this.total.text = formatTime(ms);
		}
		
		public function setBitRate(rate:String) {
			this.bitrate.text = (rate ? rate + 'kbps' : '');
		}
		
		private function formatTime(ms:Number):String {
			var s = Math.ceil(ms / 1000);
			var m = Math.floor(s / 60);
			var seconds = s % 60;
			return m + ':' + (seconds < 10 ? '0'+seconds.toString() : seconds);
		}
		
		var char:String, tf:TextFormat = new TextFormat();
		public function frameEventHandler(e:Event):void {
			if(songTitle) {
				if(this.titleScroller.text != songTitle) {
					for(var x=0; x<songTitle.length; x++) {
						char = this.titleScroller.text.charAt(x);
						if(char != songTitle.charAt(x)) {
							this.titleScroller.text = this.titleScroller.text.substring(0, x) + songTitle.charAt(x) +  this.titleScroller.text.substr(x+1);
							this.titleScroller.setTextFormat(tf);
							break;
						} else if(char == '') {
							this.titleScroller.appendText(songTitle.charAt(x));
							this.titleScroller.setTextFormat(tf);
							break;
						}
					}
				}
				if(this.titleScroller.text && this.titleScroller.text.length > songTitle.length) {
					this.titleScroller.text = this.titleScroller.text.substr(0, -1);
					this.titleScroller.setTextFormat(tf);
				}
			}
		}
	}
}