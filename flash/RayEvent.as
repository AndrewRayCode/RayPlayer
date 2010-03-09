package {
	import flash.events.Event;
	
	public class RayEvent extends flash.events.Event {
		public static const CONTROL:String = 'vol';
		public var eventData:*;
		
		public function RayEvent(val:*) {
			super(CONTROL);
			this.eventData = val;
		}
	}
}