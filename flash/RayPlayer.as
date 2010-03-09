package {
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	import flash.net.URLLoader;
	import flash.net.*;
	import flash.net.URLRequest;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import fl.controls.List;
	import fl.controls.ScrollPolicy;
	import flash.text.TextFormat;
	import flash.events.ProgressEvent;
	import fl.controls.ComboBox;
	import flash.media.SoundMixer;
	import flash.utils.ByteArray;
	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import flash.events.IOErrorEvent;
	import Cloud;
	
	public class RayPlayer extends MovieClip {
		var songs:Array = [];
		var playlist:Array = [];
		var categories:Array = [];
		var currentSong:Sound = new Sound();
		var channel:SoundChannel = new SoundChannel();  
		var transForm:SoundTransform = new SoundTransform(1, 0);  
		var songIndex = 0;
		private var maxClouds:Number = 14;
		private var clouds:Array = [];
		private var sampleFrequenciesHorizontal:Object = {};
		private var sampleFrequenciesVertical:Object = {};
		private var mutedPercent:Number;
		private var looping:Boolean = true;
		private var isMuted:Boolean = false;
		private var songPercent:Number;
		private var listTweens:Array = [];
		private var cloudTweens:Array = [];
		private var fadePrevious:Boolean = false;
		
		private var spectrum:Object = {horizontal: {bars: [], width:0}, vertical: {bars:[], width:0}};
		private var sndBytes:ByteArray = new ByteArray();
		
		var pauseTime:Number = 0;
		var isPlaying:Boolean = false;
		var hasStarted:Boolean = false;

		public function RayPlayer() {
			var xmlLoader:URLLoader = new URLLoader();
			var songData:XML = new XML();
			var xmlPath = root.loaderInfo.parameters.xml_path || '../xml/songFeed.xml';
			if(!xmlPath) {
				error('Xml path '+xmlPath+' was not readable!');
			} else {
				xmlLoader.addEventListener(Event.COMPLETE, loadXML);
				xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleError);
				xmlLoader.load(new URLRequest(xmlPath));
			}
			
			var buttons = {
				ply: faceplate.play_btn,
				nxt: faceplate.next_btn,
				pse: faceplate.pause_btn,
				prv: faceplate.prev_btn,
				mute: faceplate.mute_btn,
				unmute: faceplate.muted_btn,
				loop: faceplate.loop_btn,
				looped: faceplate.looped_btn
			};
			for each(var btn in buttons) {
				btn.addEventListener(MouseEvent.CLICK, controlClick);
			}
			
			faceplate.volume_slider.addEventListener(RayEvent.CONTROL, volumeHandler);
			faceplate.viewport.seek_bar.addEventListener(RayEvent.CONTROL, seekEventHandler);
			
			faceplate.playlist.clickHandler = playlistClick;
			faceplate.playlist.addEventListener(RayEvent.CONTROL, listHoverHandler);
			
			faceplate.addEventListener(MouseEvent.MOUSE_OVER, startMachine);
			
			var i:Number = 1;
			var bar;
			
			// Horizontal bars
			spectrum.horizontal.width = bars.horizontal.width;
			for(var x=0; x<bars.horizontal.numChildren; x++) {
				bar = bars.horizontal.getChildAt(x);
				spectrum.horizontal.bars.push({mc: bar, init_y:bar.y});
			}
			spectrum.horizontal.bars.sort(xPosSort);
			for(var qr=0; qr<spectrum.horizontal.bars.length; qr++) {
				spectrum.horizontal.bars[qr].mc.y -= qr * 2;
			}
			
			var samples:Number = Math.floor(256/spectrum.horizontal.bars.length);
			var len:Number = 0;
			for(var t:Number = 0; t<256; t++) {
				if((t - Math.round(samples / 2)) % samples == 0 && spectrum.horizontal.bars[len]) {
				   sampleFrequenciesHorizontal[t.toString()] = len;
				   len++
				}
			}
			
			// Vertical bars
			spectrum.vertical.height = bars.vertical.height;
			
			for(var z=0; z<bars.vertical.numChildren; z++) {
				bar = bars.vertical.getChildAt(z);
				spectrum.vertical.bars.push({mc: bar, init_x:bar.x});
			}
			spectrum.vertical.bars.sort(yPosSort);
			for(var qrr=0; qrr<spectrum.vertical.bars.length; qrr++) {
				spectrum.vertical.bars[qrr].mc.x -= (spectrum.vertical.bars.length * 2) - qrr * 2;
			}
			
			samples = Math.floor(256/spectrum.vertical.bars.length);
			len = 0;
			for(var q:Number = 0; q<256; q++) {
				if((q - Math.round(samples / 2)) % samples == 0 && spectrum.vertical.bars[len]) {
				   sampleFrequenciesVertical[q.toString()] = len;
				   len++
				}
			}
			
			faceplate.link.useHandCursor = true;
			faceplate.link.buttonMode = true;
			faceplate.link.addEventListener(MouseEvent.CLICK, launchHome);
		}
		
		private function launchHome(thing:* = false) {
			navigateToURL(new URLRequest('http://andrewray.me/'));
		}
		
		private function listHoverHandler(e:RayEvent) {
			var i:Number = Number(e.eventData.index);
			if(e.eventData.state == 'over')  {
				if(listTweens[i]) {
					listTweens[i].stop();
				}
				listTweens[i] = new Tween(e.eventData.mc.rowMovieClip, 'x', Regular.easeOut, e.eventData.mc.rowMovieClip.x, 15, 0.3, true);
			} else {
				if(listTweens[i]) {
					listTweens[i].stop();
				}
				listTweens[i] = new Tween(e.eventData.mc.rowMovieClip, 'x', Regular.easeOut, e.eventData.mc.rowMovieClip.x, 0, 0.3, true);
			}
		}
		
		private function popCloud(e:Event) {
			e.target.removeEventListener(MouseEvent.CLICK, popCloud);
			e.target.useHandCursor = false;
			e.target.gotoAndStop('poof');
			
			var index:Number;
			fadeOut(e.target as MovieClip, 1, true, function() {
				for(var x=0; x<clouds.length; x++) {
					if(clouds[x] == e.target) {
						index = x;
						clouds.splice(x,1);
						break;
					}
				}  
			});
			
			cloudTweens[x] = {
				a: new Tween(e.target, "scaleX", Regular.easeOut, e.target.scaleX, e.target.scaleX + 0.25, 1, true),
				b: new Tween(e.target, "scaleY", Regular.easeOut, e.target.scaleY, e.target.scaleY + 0.25, 1, true),
				c: new Tween(e.target, "y", Regular.easeOut, e.target.y, e.target.y - (e.target.height / 8), 1, true)
			};
		 	
		}
		
		private function fadeIn(mc:MovieClip, time:Number = 2, dest:Number = 1, callback:Function = null) {
			mc.alpha = 0;
			
			var twn:Tween = new Tween(mc, "alpha", Regular.easeIn, 0, dest, time, true);
			if(callback != null) {
				twn.addEventListener(TweenEvent.MOTION_FINISH, callback);
			}
		}
		
		private function fadeOut(mc:MovieClip, time:Number = 2, destroy:Boolean = false, callback:Function = null) {
			var twn:Tween = new Tween(mc, "alpha", Regular.easeIn, mc.alpha, 0, time, true);
			twn.addEventListener(TweenEvent.MOTION_FINISH, function(e:Event) {
				if(destroy) {
					mc.parent.removeChild(mc);
				}
				if(callback != null) {
					callback(e);
				}
			});
		}
		
		private function xPosSort(a:Object, b:Object) {
			if(a.mc.x > b.mc.x ) {
				return 1;
			} else if(a.mc.x < b.mc.x) {
				return -1;
			} else {
				return 0;
			}
		}
		private function yPosSort(a:Object, b:Object) {
			if(a.mc.y > b.mc.y ) {
				return 1;
			} else if(a.mc.y < b.mc.y) {
				return -1;
			} else {
				return 0;
			}
		}
		
		private function startMachine(e:Event) {
			if(!hasStarted) {
				faceplate.removeEventListener(MouseEvent.MOUSE_OVER, startMachine);
				this.addEventListener(Event.ENTER_FRAME, frameEventHandler);
				hasStarted = true;
				this.gotoAndPlay(1);
			}
		}
		
		private var flt:Number, br:Number, newY:Number, myBar, newX:Number;
		private function frameEventHandler(e:Event):void {
			// Update viewport
			if(isPlaying) {
				songPercent = (channel.position / (playlist[songIndex].length || currentSong.length)) * 100;
				faceplate.viewport.seek_bar.setPercentage(songPercent);
				faceplate.viewport.setTime(channel.position);
				
				// Render spectrum
				SoundMixer.computeSpectrum(sndBytes);
				for(var y=0; y<256; y++) {
					flt = sndBytes.readFloat();
					br = sampleFrequenciesHorizontal[y.toString()];
					if(br || br ===0) {
						myBar = spectrum.horizontal.bars[br];
						newY = myBar.init_y - (Math.abs(flt) * 100);
						if(newY < myBar.mc.y) {
							myBar.mc.y = newY; 
						} else if(myBar.mc.y < myBar.init_y) {
							myBar.mc.y += 1;
						}
					}
				}
				for(var z=0; z<256; z++) {
					flt = sndBytes.readFloat();
					br = sampleFrequenciesVertical[z.toString()];
					if(br || br ===0) {
						myBar = spectrum.vertical.bars[br];
						newX = myBar.init_x - (Math.abs(flt) * 100);
						if(newX < myBar.mc.x) {
							myBar.mc.x = newX; 
						} else if(myBar.mc.x < myBar.init_x) {
							myBar.mc.x += 1;
						}
					}
				}
				if(songPercent >= 99.7) {
					if(looping) {
						nextSong();
					} else {
						pauseSong();
						toggleBtns();
						faceplate.viewport.setTime(0);
						seekSong(0);
					}
				}
			} else {
				for(var f=0; f<spectrum.vertical.bars.length; f++) {
					if(spectrum.vertical.bars[f].mc.x < spectrum.vertical.bars[f].init_x) {
						spectrum.vertical.bars[f].mc.x += 0.5;
					}
				}
				for(var n=0; n<spectrum.horizontal.bars.length; n++) {
					if(spectrum.horizontal.bars[n].mc.y < spectrum.horizontal.bars[n].init_y) {
						spectrum.horizontal.bars[n].mc.y += 0.5;
					}
				}
			}
		}
		
		private function volumeHandler(e:RayEvent):void {
			var pct = Number(e.eventData);
			setVolume(pct);
			if(pct == 0) {
				toggleMute(true);
			} else if(isMuted) {
				toggleMute();
			}
		}
		
		public function setVolume(percent:Number):void {
			transForm.volume = (percent / 100);			
			channel.soundTransform = transForm;
		}
		
		private function controlClick(e:Event) {
			switch(e.target.name) {
				case 'play_btn':
					this.toggleBtns();
					this.playSong();
					break;
				case 'pause_btn':
					this.toggleBtns();
					this.pauseSong();
					break;
				case 'next_btn':
					this.nextSong();
					break;
				case 'prev_btn':
					this.previousSong();
					break;
				case 'mute_btn':
					this.toggleMute();
					this.mute();
					break;
				case 'muted_btn':
					this.toggleMute();
					this.unmute();
					break;
				case 'loop_btn':
				case 'looped_btn':
					toggleLooping();
					break;
			}
		}
		
		private function toggleLooping(showLooping:Boolean = false):void {
			looping = !looping;
			if(faceplate.looped_btn.visible || showLooping) {
				faceplate.looped_btn.visible = false;
				faceplate.loop_btn.visible = true;
			} else {
				faceplate.looped_btn.visible = true;
				faceplate.loop_btn.visible = false;
			}
		}
		
		private function toggleMute(showMuted:Boolean = false):void {
			isMuted = !isMuted;
			if(faceplate.mute_btn.visible || showMuted) {
				faceplate.muted_btn.visible = true;
				faceplate.mute_btn.visible = false;
			} else {
				faceplate.muted_btn.visible = false;
				faceplate.mute_btn.visible = true;
			}
		}
		
		public function mute() {
			isMuted = true;
			setVolume(0);
			faceplate.volume_slider.setPercentage(0);
			mutedPercent = faceplate.volume_slider.percent;
		}
		
		public function unmute() {
			isMuted = false;
			if(!mutedPercent) {
				setVolume(100);
				faceplate.volume_slider.setPercentage(100);
			} else {
				setVolume(mutedPercent);
				faceplate.volume_slider.setPercentage(mutedPercent);
			}
		}
		
		public function toggleBtns(showPausing:Boolean = false):void {
			if(faceplate.play_btn.visible || showPausing) {
				faceplate.pause_btn.visible = true;
				faceplate.play_btn.visible = false;
			} else {
				faceplate.pause_btn.visible = false;
				faceplate.play_btn.visible = true;
			}
		}
		
		public function stopSong():void {
			channel.stop();
			pauseTime = 0;
		}
		public function nextSong():void {
			stopSong();
			songIndex++;
			if(songIndex == playlist.length) {
				songIndex = 0;
			}
			loadSong();
			playSong();
		}
		public function previousSong():void {
			stopSong();
			songIndex--;
			if(songIndex == -1) {
				songIndex = playlist.length - 1;
			}
			loadSong();
			playSong();
		}
		
		private function ioErrorHandler(e:IOErrorEvent) {
			error('Oh no song error! '+e+'!');
		}
		
		private function loadSong():void {
			faceplate.playlist.setSelected(songIndex, fadePrevious);
			fadePrevious = true;
			
			var soundRequest:URLRequest = new URLRequest(playlist[songIndex].file);
			if(currentSong) {
				currentSong.removeEventListener(ProgressEvent.PROGRESS, songLoadHandler);
			}
			currentSong = new Sound();
			currentSong.load(soundRequest);

			currentSong.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			currentSong.addEventListener(ProgressEvent.PROGRESS, songLoadHandler);
			currentSong.addEventListener(Event.COMPLETE, songLoadedHandler);
			
			faceplate.viewport.setTitle(playlist[songIndex].title);
			faceplate.viewport.setBitRate(playlist[songIndex].bitrate);
			faceplate.viewport.setCategory(playlist[songIndex].category);
			faceplate.viewport.setTotal(playlist[songIndex].length);
		}
		
		public function playSong():void {
			toggleBtns(true);
			if(!playlist[songIndex]) {
				error('Something went disgustingly wrong!');
			}
			channel.stop();
			channel = currentSong.play(pauseTime);
			channel.soundTransform = transForm;
			isPlaying = true;
		}
		
		public function pauseSong():void {
			isPlaying = false;
			pauseTime = channel.position;
			channel.stop();
		}
		
		public function loadXML(e:Event):void {
			parseSongs(new XML(e.target.data));
		}
		
		public function seekEventHandler(e:RayEvent):void {
			this.seekSong(Number(e.eventData));
		}
		
		public function seekSong(percent:Number):void {
			pauseTime = currentSong.length * (percent / 100);
			if(isPlaying) {
				playSong();
			}
			faceplate.viewport.setTime(pauseTime);
		}
		
		private function songLoadHandler(e:ProgressEvent) {
			faceplate.viewport.seek_bar.setLoaded((e.bytesLoaded / e.bytesTotal) * 100);
			if(playlist[songIndex].length == 0) {
				faceplate.viewport.setTotal(currentSong.length);
			}
		}
		private function songLoadedHandler(e:Event) {
			faceplate.viewport.seek_bar.setLoaded(100);
			if(playlist[songIndex].length == 0) {
				faceplate.viewport.setTotal(currentSong.length);
			}
		}
		
		public function parseSongs(xml:XML) {
			var songs_xml:XMLList = xml.children();
			var category;
			for each(var song:XML in songs_xml) {
				category = song.attribute('category').toString();
				if(categories.indexOf(category) == -1) {
					categories.push(category);
				}
				songs.push({
					title: song.attribute('title').toString(),
					category: category,
					file: song.attribute('file').toString(),
					loadStarted: false,
					length: Number(song.attribute('length').toString()),
					bitrate: song.attribute('bitrate').toString()
				});
			}
			
			// Generate the categories for the dropdown
			categories.sort();
			category_dropdown.labelField = 'label';
			category_dropdown.addItem({label: 'All Categories', data: 'All Categories'});
			
			for(var x=0; x<categories.length; x++) {
				category_dropdown.addItem({label: categories[x], data: categories[x]});
			}
			category_dropdown.addEventListener(Event.CHANGE, changeCategory);
			
			var whiteTf:TextFormat = new TextFormat();
			whiteTf.color = 0xeeeeee;
			whiteTf.font = 'Arial';
			whiteTf.size = 10;
			category_dropdown.textField.setStyle("textFormat", whiteTf);
			category_dropdown.dropdown.setRendererStyle("textFormat", whiteTf);
			
			makePlaylist({category: '*'});
			loadSong();
		}
		
		private function changeCategory(e:Event) {
			var cat = e.target.value;
			songIndex = 0;
			makePlaylist({category: cat == 'All Categories' ? '*' : cat});
		}
		
		private function makePlaylist(obj:Object):void {
			playlist = [];
			songIndex = 0;
			fadePrevious = false;
			var valid;
			for(var x=0; x<songs.length; x++) {
				valid = true;
				for(var key in obj) {
					if(songs[x][key] != obj[key] && obj[key] != '*') {
						valid = false;
					}
				}
				if(valid) {
					playlist.push(songs[x]);
				}
			}
			this.refreshList();
		}
		
		private function playlistClick(i:Number, data:Object) {
			stopSong();
			songIndex = i;
			loadSong();
			playSong();
		}
		
		function refreshList():void {
			//faceplate.playlist.zebra = false;
			faceplate.playlist.rowMovieClip = PlaylistRow;
			faceplate.playlist.playlistSelected = PlayListSelected;
			faceplate.playlist.empty();
			
			for(var x=0; x<playlist.length; x++) {
				faceplate.playlist.addItem({
					title:playlist[x].title,
					category:playlist[x].category
				});
			}
		}
		
		public function handleError(e:Event):void {
			
		}
		
		public function error(msg) {
			this.debug_box.appendText(msg+'\n');
		}
		
		public function debug(msg) {
			this.debug_box.text = (msg+'\n');
		}
		
		private function randInt(min,max) {
		    return Math.floor(Math.random()*(max-min+1))+min;
		}
	}
}