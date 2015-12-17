package binary{
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.media.Sound;
	import flash.utils.Timer;

	public class Chessman extends MovieClip{
		private var inc:uint = 0;
		public var bPlayer:Boolean = false;
		public function Chessman() {
			//设置闪烁的定时器
			var m_time:Timer = new Timer(100,6);
			m_time.addEventListener(TimerEvent.TIMER, twinkle);
			m_time.addEventListener(TimerEvent.TIMER_COMPLETE, twinkleEnd);
			m_time.start();
			//设置每次的声音
			var m_music:Sound = new ChessMusic();
			m_music.play();
		}
		//每次闪烁
		public function twinkle(e:TimerEvent):void {		
			if(bPlayer){
				this.alpha = 1;
			}else{
				this.alpha = 0.2;
			}
			bPlayer =! bPlayer;
		}
		//闪烁结束
		public function twinkleEnd(e:TimerEvent):void {
			this.alpha = 1;
		}
	}
}
