package {
	import flash.display.*;
	import flash.events.*;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	import RayEvent;
	import flash.text.TextField;
	import ListComponentRow;
	import fl.containers.ScrollPane;
	import fl.controls.ScrollPolicy;
	import flash.utils.getQualifiedClassName;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.filters.BlurFilter;
	
	public class ListComponent extends MovieClip {
		
		public var listWidth;
		public var listHeight;
		public var rows:Array = [];
		public var zebra:Boolean = true;
		private var listRowHeight:Number = 20;
		private var rowWidth:Number;
		public var rowMovieClip:Class;
		public var playlistSelected:Class;
		public var clickHandler:Function;
		private var scrolling:Boolean = false;
		private var container:MovieClip;
		private var tweens:Array = [];
		private var animated:Boolean = true;
		private var selectedIndex:Number;
		private var blurTweens:Array = [];
		private var blurMax:Number = 12;
		private var isScrolling:Boolean = false;
		private var targetScroll:Number;
		
		public function ListComponent() {
			rowWidth = this.width;
			listHeight = this.height;
			this.width = 100;
			this.height = 100;
			
			container = new MovieClip();
			container.name = 'container';
			this.addChild(container);
			
			scroller.width = rowWidth;
			scroller.height = listHeight;
			scroller.source = container;
			scroller.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			this.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			this.addEventListener(MouseEvent.MOUSE_WHEEL, mouseDownHandler);
		}
		
		private function scrollTo(mc:MovieClip) {
			
			var pct_scrolled = (scroller.verticalScrollPosition / scroller.maxVerticalScrollPosition);
			var viewport_top = pct_scrolled * (container.height - listHeight);
			var viewport_bottom = viewport_top + listHeight;

			if(mc.y < viewport_top) {
				isScrolling = true;
				targetScroll = scroller.verticalScrollPosition - 10 -(((viewport_top - mc.y) / listHeight) * scroller.maxVerticalScrollPosition);
			} else if (mc.y + mc.height > viewport_bottom) {
				isScrolling = true;
				targetScroll = scroller.verticalScrollPosition + 10 + ((((mc.y + listRowHeight) - viewport_bottom) / listHeight) * scroller.maxVerticalScrollPosition);
			}
		}
		
		private function enterFrameHandler(e:Event) {
			if(isScrolling) {
				if(targetScroll > scroller.verticalScrollPosition) {
					scroller.verticalScrollPosition += (targetScroll - scroller.verticalScrollPosition) / 4;
				} else if(targetScroll < scroller.verticalScrollPosition) {
					scroller.verticalScrollPosition -=  (scroller.verticalScrollPosition - targetScroll) / 4;
				}
				if(Math.abs(targetScroll - scroller.verticalScrollPosition) < 0.01) {
					isScrolling = false;
				}
			}
			
			for(var x=0; x<blurTweens.length; x++) {
				if(blurTweens[x]) {
					if(blurTweens[x].direction == 'out') {
						blurTweens[x].value += 0.5;
						blurTweens[x].filter = new BlurFilter(blurTweens[x].value, blurTweens[x].value, 2);
						blurTweens[x].mc.filters = [blurTweens[x].filter];
						
						if(blurTweens[x].value >= blurMax) {
							blurTweens[x] = null;
						}
					} else if(blurTweens[x].direction == 'in') {
						blurTweens[x].value -= 0.5;
						blurTweens[x].filter = new BlurFilter(blurTweens[x].value, blurTweens[x].value, 2);
						blurTweens[x].mc.filters = [blurTweens[x].filter];
						
						if(blurTweens[x].value == 0) {
							blurTweens[x].mc.filters = [];
							blurTweens[x] = null;
						}
					}
				}
			}
		}
		
		private function startBlurOut(index:Number, mc:MovieClip) {
			if(blurTweens[index] && blurTweens[index].tween) {
				blurTweens[index].tween.stop();
			}
			blurTweens[index] = {mc: mc, direction: 'out', value:0, tween: new Tween(mc, 'alpha', Regular.easeOut, 1, 0, 2, true)};
		}
		private function startBlurIn(index:Number, mc:MovieClip) {
			if(blurTweens[index] && blurTweens[index].tween) {
				blurTweens[index].tween.stop();
			}
			blurTweens[index] = {mc: mc, direction: 'in', value:blurMax, tween: new Tween(mc, 'alpha', Regular.easeOut, 0, 1, 0.2, true)};
		}
		
		public function setRowHeight(row, height) {
			
		}
		public function setRowHeightGlobal(height:Number) {
			this.listRowHeight = listRowHeight;
		}
		
		public function addItem(obj:Object) {
			var row:MovieClip = new MovieClip();
			
			row.bg = new ListComponentRow();
			row.bg.name = 'bg';
			row.bg.buttonMode = true;
			row.bg.useHandCursor = true;
			row.addChild(row.bg);
			row.addEventListener(MouseEvent.ROLL_OVER, function(e:Event) {hoverState(row, e);});
			row.addEventListener(MouseEvent.ROLL_OUT, function(e:Event) {outState(row, e);});
			row.addEventListener(MouseEvent.CLICK, function(e:Event) {clickState(row, e);});
			if(zebra) {
				row.bg.gotoAndStop((rows.length % 2) + 1);
			}
			
			if(animated) {
				row.hover = new ListComponentRow();
				row.hover.name = 'hover';
				row.hover.buttonMode = true;
				row.hover.useHandCursor = true;
				row.hover.gotoAndStop(zebra ? (rows.length % 2) + 3 : 3);
				row.hover.width = this.rowWidth;
				row.hover.height = listRowHeight;
				row.hover.alpha = 0;
				row.addChild(row.hover);
			}
			
			row.name = (rows.length).toString();
			row.buttonMode = true;
			row.useHandCursor = true;
			rows.push({container: row, data: obj});

			this.container.addChild(row);
			row.bg.width = this.rowWidth;
			row.bg.height = listRowHeight;
			row.x = 0;
			
			var prev = rows[rows.length-2];
			if(prev) {
				row.y = prev.container.y + prev.container.height - 1;
			}
			
			if(rowMovieClip) {
				var clip = new rowMovieClip();
				var child;
				for(var key in obj) {
					child = clip.getChildByName(key);
					if(child && child.text) {
						child.text = obj[key];
					}
				}
				row.rowMovieClip = clip;
				row.addChild(clip);
				clip.buttonMode = true;
				clip.useHandCursor = true;
			}
			
			if(playlistSelected) {
				var icon = new playlistSelected();
				row.playlistSelected = icon;
				row.addChild(icon);
				icon.buttonMode = true;
				icon.useHandCursor = true;
				icon.alpha = 0;
			}
			
			
			var coat = new Blank();
			coat.width = this.rowWidth;
			coat.height = listRowHeight;
			coat.buttonMode = true;
			coat.useHandCursor = true;
			row.addChild(coat);
			
			container.height = rows.length * listRowHeight;
			
			scroller.update();
		}
		
		public function empty():void {
			for(var x=0; x<rows.length; x++) {
				rows[x].container.parent.removeChild(rows[x].container);
			}
			rows = [];
		}
		
		private function clickState(row, e:Event) {
			if(this.clickHandler != null) {
				var i = Number(row.name);
				this.clickHandler(i, this.rows[i].data);
			}
		}
		
		private function mouseDownHandler(e:Event) {
			isScrolling = false;
		}
		
		var index:Number;
		private function hoverState(row, e:Event):void {
			index = Number(row.name);
			
			row.parent.swapChildren(row, row.parent.getChildAt(row.parent.numChildren - 1));
			var bg = row.getChildByName('bg');
			if(animated) {
				if(tweens[index]) {
					tweens[index].stop();
				}
				tweens[index] = new Tween(row.hover, 'alpha', Regular.easeOut, row.hover.alpha, 1, 0.1, true);
			} else {
				bg.gotoAndStop(!zebra ? 3 : (index % 2) + 3);
			}
			
			dispatchEvent(new RayEvent({state: 'over', mc: row, index:index}));
		}
		private function outState(row, e:Event):void {
			index = Number(row.name);
			
			var bg = row.getChildByName('bg');
			if(animated) {
				var t:Tween
				if(tweens[index]) {
					tweens[index].stop();
				}
				tweens[index] = new Tween(row.hover, 'alpha', Regular.easeOut, row.hover.alpha, 0, 0.5, true);
			} else {
				bg.gotoAndStop(!zebra ? 1 : ((Number(bg.parent.name)) % 2) + 1);
			}
				
			dispatchEvent(new RayEvent({state: 'out', mc: row, index:index}));
		}
		
		public function setSelected(index:Number, fadePrevious:Boolean = true):void {
			if((selectedIndex || selectedIndex === 0) && rows[selectedIndex] && rows[selectedIndex].container && fadePrevious) {
				startBlurOut(selectedIndex, rows[selectedIndex].container.playlistSelected);
			}

			selectedIndex = index;
			
			scrollTo(rows[selectedIndex].container);
			startBlurIn(selectedIndex, rows[selectedIndex].container.playlistSelected);
		}
	}
}