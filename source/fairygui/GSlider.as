package fairygui {
	import fairygui.utils.ToolSet;
	
	import laya.events.Event;
	import laya.maths.Point;
	
	public class GSlider extends GComponent {
		private var _max: Number = 0;
		private var _value: Number = 0;
		private var _titleType: int;
		
		private var _titleObject: GTextField;
		private var _aniObject: GObject;
		private var _barObjectH: GObject;
		private var _barObjectV: GObject;
		private var _barMaxWidth: Number = 0;
		private var _barMaxHeight: Number = 0;
		private var _barMaxWidthDelta: Number = 0;
		private var _barMaxHeightDelta: Number = 0;
		private var _gripObject: GObject;
		private var _clickPos: Point;
		private var _clickPercent: Number = 0;
		
		public function GSlider() {
			super();
			
			this._titleType = ProgressTitleType.Percent;
			this._value = 50;
			this._max = 100;
			this._clickPos = new laya.maths.Point();
		}
		
		public function get titleType(): int {
			return this._titleType;
		}
		
		public function set titleType(value: int):void {
			this._titleType = value;
		}
		
		public function get max(): Number {
			return this._max;
		}
		
		public function set max(value: Number):void {
			if (this._max != value) {
				this._max = value;
				this.update();
			}
		}
		
		public function get value(): Number {
			return this._value;
		}
		
		public function set value(value: Number):void {
			if (this._value != value) {
				this._value = value;
				this.update();
			}
		}
		
		public function update(): void {
			var percent: Number = Math.min(this._value / this._max, 1);
			this.updateWidthPercent(percent);
		}
		
		private function updateWidthPercent(percent: Number): void {
			if (this._titleObject) {
				switch (this._titleType) {
					case ProgressTitleType.Percent:
						this._titleObject.text = Math.round(percent * 100) + "%";
						break;
					
					case ProgressTitleType.ValueAndMax:
						this._titleObject.text = this._value + "/" + this._max;
						break;
					
					case ProgressTitleType.Value:
						this._titleObject.text = "" + this._value;
						break;
					
					case ProgressTitleType.Max:
						this._titleObject.text = "" + this._max;
						break;
				}
			}
			
			if (this._barObjectH)
				this._barObjectH.width = (this.width - this._barMaxWidthDelta) * percent;
			if (this._barObjectV)
				this._barObjectV.height = (this.height - this._barMaxHeightDelta) * percent;
			
			if (this._aniObject is GMovieClip)
				GMovieClip(this._aniObject).frame = Math.round(percent * 100);
		}
		
		override protected function constructFromXML(xml: Object): void {
			super.constructFromXML(xml);
			
			xml = ToolSet.findChildNode(xml, "Slider");
			
			var str: String;
			str = xml.getAttribute("titleType");
			if(str)
				this._titleType = ProgressTitleType.parse(str);
			
			this._titleObject = GTextField(this.getChild("title"));
			this._barObjectH = this.getChild("bar");
			this._barObjectV = this.getChild("bar_v");
			this._aniObject = this.getChild("ani");
			this._gripObject = this.getChild("grip");
			
			if(this._barObjectH) {
				this._barMaxWidth = this._barObjectH.width;
				this._barMaxWidthDelta = this.width - this._barMaxWidth;
			}
			if(this._barObjectV) {
				this._barMaxHeight = this._barObjectV.height;
				this._barMaxHeightDelta = this.height - this._barMaxHeight;
			}
			if(this._gripObject) {
				this._gripObject.on(Event.MOUSE_DOWN, this, this.__gripMouseDown);
			}
		}
		
		override protected function handleSizeChanged(): void {
			super.handleSizeChanged();
			
			if(this._barObjectH)
				this._barMaxWidth = this.width - this._barMaxWidthDelta;
			if(this._barObjectV)
				this._barMaxHeight = this.height - this._barMaxHeightDelta;
			if(!this._underConstruct)
				this.update();
		}
		
		override public function setup_afterAdd(xml:Object): void {
			super.setup_afterAdd(xml);
			
			xml = ToolSet.findChildNode(xml, "Slider");
			if (xml) {
				this._value = parseInt(xml.getAttribute("value"));
				this._max = parseInt(xml.getAttribute("max"));
			}
			
			this.update();
		}
		
		private function __gripMouseDown(evt: Event): void {
			this._clickPos = this.globalToLocal(Laya.stage.mouseX,Laya.stage.mouseY);
			this._clickPercent = this._value / this._max;
			
			Laya.stage.on(Event.MOUSE_MOVE, this, this.__gripMouseMove);
			Laya.stage.on(Event.MOUSE_UP,this,this.__gripMouseUp);
		}
		
		private static var sSilderHelperPoint: Point = new Point();
		private function __gripMouseMove(evt: Event): void {
			var pt: Point = this.globalToLocal(Laya.stage.mouseX,Laya.stage.mouseY,GSlider.sSilderHelperPoint);
			var deltaX: Number = pt.x - this._clickPos.x;
			var deltaY: Number = pt.y - this._clickPos.y;
			
			var percent: Number;
			if (this._barObjectH)
				percent = this._clickPercent + deltaX / this._barMaxWidth;
			else
				percent = this._clickPercent + deltaY / this._barMaxHeight;
			if (percent > 1)
				percent = 1;
			else if (percent < 0)
				percent = 0;
			var newValue: Number = Math.round(this._max * percent);
			if (newValue != this._value) {
				this._value = newValue;
				Events.dispatch(Events.STATE_CHANGED, this.displayObject, evt);
			}
			this.updateWidthPercent(percent);
		}
		
		private function __gripMouseUp(evt: Event): void {
			var percent: Number = this._value / this._max;
			this.updateWidthPercent(percent);
			
			Laya.stage.off(Event.MOUSE_MOVE, this, this.__gripMouseMove);
			Laya.stage.off(Event.MOUSE_UP,this,this.__gripMouseUp);
		}
	}
}