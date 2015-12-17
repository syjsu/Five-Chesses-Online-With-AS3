package binary{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.text.TextField;
	import flash.display.MovieClip;
	import com.adobe.serialization.json.JSON;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.utils.getTimer;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.Timer;

	[SWF(width="495", height="600", frameRate="30")]

	/**
	 *1205531107 苏颖杰  1205531105 邓翊臻
	 *
	 * 在线玩的地址 http://5.littlesmallsu.sinaapp.com/chess.swf
	 */

	public class main extends MovieClip {

		private const gridsize:Number = 20;	//棋盘每行间隔的像素
		private const gridnum:Number = 15;	//棋盘每行棋子数量

		private var crtNum:int = 1;			//当前下棋的步数
		private var crtNumWeb:int = -1;		//当前服务器下棋的步数

		private const NOTHING:int = 0;		//没有的全局变量
		private const BLACK:int = 1;		//黑棋的全局变量
		private const WHITE:int = 2;		//白棋的全局变量

		private var crtSide:int = BLACK;	//当前的下棋方
		private var mySide:int = WHITE;		//我用的下棋方
		private var otherSide:int;			//当前不下棋那一方

		private var canPlay:Boolean = false;//能不能下棋
		private var aGridState:Array = [];	//当前棋盘下棋的状态 注意 X和Y要反过来
		private var aChessmen:Array = [];	//存储舞台上的棋盘信息的相关数组

		private var _WebCount:int = 0;	//向服务器请求时的计数器，用来刷新请求
		private var _deltaTime = 800;	//请求的时间间隔
		private var myTimer:Timer = new Timer (_deltaTime, int.MAX_VALUE);//向服务器请求的计数器

		private var mySound:Sound = new BackgroundMusic();//背景音乐
		private	var channel:SoundChannel = null;//背景音乐控制器
		private var pausePosition:int = 0;//标记当前播放的位置
		private var isMusic:Boolean = true;//变量标记是否在播放背景音乐

		//构成函数,初始化执行
		public function main() {
			//初始化
			init();

			//定时器开始工作
			myTimer.start();

			//点击棋盘事件回调
			mcChessboard.addEventListener(MouseEvent.MOUSE_DOWN,chessboardClick_Handler);
			//开始按钮事件回调
			btnStart.addEventListener(MouseEvent.CLICK,btnStart_Handler);
			//重新开始按钮事件回调
			btnReplay.addEventListener(MouseEvent.CLICK,btnReplay_Handler);
			//交换棋子按钮事件回调
			mcSelectChessman.addEventListener(MouseEvent.MOUSE_DOWN, selectChessman);
			//设置定时器向服务器访问
			myTimer.addEventListener(TimerEvent.TIMER, HTTPRequest);
			//打开背景音乐和暂停背景音乐
			btnSound.addEventListener(MouseEvent.CLICK, btnSound_Handler);

			//播放背景音乐
			channel = mySound.play(0,int.MAX_VALUE);

		}
		//打开背景音乐和暂停背景音乐的回调
		public function btnSound_Handler(e:MouseEvent){
			if(isMusic){
				pausePosition = channel.position;
				channel.stop();
				btnSound.gotoAndStop("stop");
			}else{
				channel = mySound.play(pausePosition, int.MAX_VALUE);
				btnSound.gotoAndStop("play");
			}
			isMusic = !isMusic;
		}
		//初始化棋盘
		private function init():void {

			//修改文字
			var _message:String = "您可以通过左边的选棋按钮更改棋子,当前轮到";
			if(crtSide == WHITE){
				_message += "【白色】棋子下棋"
			}else{
				_message += "【黑色】棋子下棋"
			}
			my_message.text = _message;

			crtNum = 1;
			crtSide = BLACK;

			if(aChessmen.length != 0){
				for(var i:int=0;i<aChessmen.length;i++){
					mcChessboard.removeChild(aChessmen[i]);
				}
			}
			//初始化棋盘状态
			for (var j:int=0; j<gridnum; j++) {
				aGridState[j] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
			}
			aChessmen = [];
			//隐藏游戏状态的提示文字
			mcGameState.visible = false;
			//初始化对手的棋子
			otherSide = WHITE + BLACK - mySide;
			//棋盘的透明度恢复
			mcChessboard.alpha = 1;
		}

		//鼠标点击棋盘触发的事件
		public function chessboardClick_Handler(e:MouseEvent):void {

			trace("canPlay=" + canPlay + " crtSide=" + crtSide + " mySide=" + mySide);

			//判断是否能下棋
			if(!canPlay || crtSide != mySide || e.target.name != "mcChessboard"){
				return;
			}
			else {
				canPlay = false;

				//获取当前点击的位置
				var crtx:int = Math.floor(e.localX / gridsize);
				var crty:int = Math.floor(e.localY / gridsize);

				//如果当前位置有棋子了，就不能下棋
				if (aGridState[crty][crtx]){
					canPlay = true;
					return;
				}
				//向服务器发送下棋的请求
				HTTPDownPos(crtx, crty);
			}
		}

		//下棋的函数
		public function AddChessman(toX:int,toY:int,chessSide:int):void {
				//新建棋子对象
				var chessman:Chessman;
				if (chessSide == BLACK) {
					chessman = new BlackChessman();
				} else {
					chessman = new WhiteChessman();
				}
				//在棋盘数组上记录我的下棋
				aGridState[toY][toX] = chessSide;

				//打印当前的棋盘到控制台
				trace("测试：当前的步数是："+crtNum + "当前的下棋方是"+chessSide +"轮到下棋方是" + crtSide);
				trace("测试：当前的棋盘是：");
				for (var i:int=0; i<gridnum; i++) {
					trace(aGridState[i]);
				}

				//计算放在舞台的棋盘上棋子的位置，并把棋子放到棋盘上
				chessman.x = (toX + 0.5) * gridsize;
				chessman.y = (toY + 0.5) * gridsize;
				aChessmen.push(chessman);
				mcChessboard.addChild(chessman);

				//检查是否有人赢了
				checkWinner(toX,toY,chessSide);
				//交换对手
				crtSide = WHITE + BLACK - chessSide;

				//修改文字
				var _message:String = "您可以通过左边的选棋按钮更改棋子,当前轮到";
				if(crtSide == WHITE){
					_message += "【白色】棋子下棋"
				}else{
					_message += "【黑色】棋子下棋"
				}
				my_message.text = _message;

				//解除下棋锁定
				canPlay = true;
		}

		/**
		 * [checkWinner 检查是否获胜]
		 * @param  xp   [当前下棋的x]
		 * @param  yp   [当前下棋的y]
		 * @param  side [当前下棋的一方]
		 * @return      [description]
		 */
		private function checkWinner(xp:int,yp:int,side:int){
			/**
			 * 比如说 现在下棋的是白棋 WHITE = 2 那么str="22222"
			 * 假设我读取当前下棋方向打横的位置 getXLine()读取的结果为
			 * str1 =  getXLine(....) =  "112222111" 最大长度为9个棋子
			 * str1.indexOf(str) =  2  即为第二个位置开始匹配到字符串 >-1 故存在这样的字符串
			 * 所以一行的下棋大于5个
			 */
			//转换成获胜的字符串
			var str:String = (side * 11111).toString();
			var winner:int = 0;
			//判断横、竖、斜左、斜右的情况
			var str1:String = getXLine(aGridState,xp,yp,side).join("");
			var str2:String = getYLine(aGridState,xp,yp,side).join("");
			var str3:String = getXYLine(aGridState,xp,yp,side).join("");
			var str4:String = getYXLine(aGridState,xp,yp,side).join("");
			//如果横、竖、斜左、斜右字符串包含获胜的字符串
			if(str1.indexOf(str)>-1 || str2.indexOf(str)>-1 || str3.indexOf(str)>-1 || str4.indexOf(str)>-1)
				winner = side;
			//获胜
			if(winner){
				doWin(winner);
			}
		}
		//使某一方获胜 处理场景
		private function doWin(side:int):void{
			mcGameState.visible = true;
			canPlay = false;
			mcChessboard.alpha = 0.5;
			if(side == mySide){
				mcGameState.gotoAndStop("win");
			}
			else{
				mcGameState.gotoAndStop("lose");
			}
		}
		/**
		 * [getXLine 判断横方向是否够5个]
		 * @param  aposition [当前棋盘的状态]
		 * @param  xp        [当前下棋的x]
		 * @param  yp        [当前下棋的y]
		 * @param  side      [当前下棋的一方]
		 * @return           [返回当前情况的数组]
		 */
		private function getXLine(aposition:Array,xp:int,yp:int,side:int):Array{
			var arr:Array = [];
			var xs:int,ys:int,xe:int,ye:int;
			//x_start为开始的地方、x_end为结束的地方
			xs = xp - 5>0 ? xp - 5:0;
			xe = xp + 5>= gridnum?gridnum:xp + 5;
			//把下棋步骤之后的结果压入数组 并返回
			for(var i:int=xs;i<=xe;i++){
				if(i == xp)
					arr.push(side);
				else{
					arr.push(aGridState[yp][i])
				}
			}
			return arr;
		}
		/**
		 * [getYLine 判断竖方向是否够5个]
		 * @param  aposition [当前棋盘的状态]
		 * @param  xp        [当前下棋的x]
		 * @param  yp        [当前下棋的y]
		 * @param  side      [当前下棋的一方]
		 * @return           [返回当前情况的数组]
		 */
		private function getYLine(aposition:Array,xp:int,yp:int,side:int):Array{
			var arr:Array = [];
			var xs:int,ys:int,xe:int,ye:int;
			//y_start为开始的地方、y_end为结束的地方
			ys = yp - 5>0 ? yp - 5:0;
			ye = yp + 5>= gridnum?gridnum:yp + 5;
			//把下棋步骤之后的结果压入数组 并返回
			for(var i:int=ys;i<ye;i++){
				if(i == yp)
					arr.push(side);
				else{
					arr.push(aposition[i][xp])
				}
			}
			return arr;
		}
		/**
		 * [getXYLine 判断斜左方向是否够5个]
		 * @param  aposition [当前棋盘的状态]
		 * @param  xp        [当前下棋的x]
		 * @param  yp        [当前下棋的y]
		 * @param  side      [当前下棋的一方]
		 * @return           [返回当前情况的数组]
		 */
		private function getXYLine(aposition:Array,xp:int,yp:int,side:int):Array{
			var arr:Array = [];
			var xs:int,ys:int,xe:int,ye:int;
			//x_start为开始的地方、x_end为结束的地方
			//y_start为开始的地方、y_end为结束的地方
			xs = yp > xp ? 0 : xp - yp;
			ys = xp > yp ? 0 : yp - xp;
			xe = gridnum - ys;
			ye = gridnum - xs;
			//把下棋步骤之后的结果压入数组 并返回
			var pos:int;
			for(var i:int=0;i<(xe-xs<ye-ys?xe-xs:ye-ys);i++){
					if(ys + i == yp && xs + i == xp){
						arr.push(side);
						pos = i;
					}
					else{
						arr.push(aposition[ys + i][ xs + i]);
					}
			}
			arr = arr.slice(pos-4>0?pos-4:0,pos+5>arr.length?arr.length:pos+5);
			return arr;
		}
		/**
		 * [getYXLine 判断斜右方向是否够5个]
		 * @param  aposition [当前棋盘的状态]
		 * @param  xp        [当前下棋的x]
		 * @param  yp        [当前下棋的y]
		 * @param  side      [当前下棋的一方]
		 * @return           [返回当前情况的数组]
		 */
		private function getYXLine(aposition:Array,xp:int,yp:int,side:int):Array{
			var arr:Array = [];
			var xs:int, ys:int, xe:int, ye:int;
			//x_start为开始的地方、x_end为结束的地方
			//y_start为开始的地方、y_end为结束的地方
			var num:int = gridnum;
			var half:int = Math.ceil(gridnum/2);
			xs = xp + yp < num?0:(xp + yp - num + 1);
			ys = xs;
			xe = xp + yp >= num?num-1:(xp + yp);
			ye = xe;
			//把下棋步骤之后的结果压入数组 并返回
			var pos:int;
			for(var i:int=0;i<(xp + yp>=num?2*num-xp-yp-1:xp+yp+1);i++){
					if(ye - i == yp && xs + i == xp){
						arr.push(side);
						pos = i;
					}
					else
						arr.push(aposition[ye - i][ xs + i]);
			}
			arr = arr.slice(pos-4>0?pos-4:0,pos+5>arr.length?arr.length:pos+5);
			return arr;
		}

		//开始按钮的回调
		private function btnStart_Handler(e:MouseEvent):void {
			canPlay = true;
			btnStart.visible = false;
			crtNum = 1;
			HTTPResetGame();
		}
		//重新开始按钮的回调
		private function btnReplay_Handler(e:MouseEvent):void{
			//初始化棋盘
			init();
			//隐藏开始游戏的按钮
			canPlay = true;
			btnStart.visible = false;
			crtNum = 1;
			HTTPResetGame();
		}
		//选择下棋按钮的回调
		private function selectChessman(e:MouseEvent):void{
			mySide = otherSide;
			otherSide = WHITE + BLACK - mySide;
			if(mySide == WHITE){
				mcSelectChessman.gotoAndStop("white");
			}else{
				mcSelectChessman.gotoAndStop("black");
			}
			canPlay = true;
		}
		//定时向服务器请求
		function HTTPRequest(e:TimerEvent):void {
			var tmp:String = "&c="+mySide;
			SendData(tmp);
		}
		//向服务器发送初始化的请求
		function HTTPResetGame():void {
			var tmp:String = "&ini=1";
			SendData(tmp);
		}
		//向服务器发送下棋的请求
		function HTTPDownPos(myX:int,myY:int):void {
			var tmp:String = "&c="+mySide+"&x="+myX+"&y="+myY;
			SendData(tmp);
		}
		//发送请求
		function SendData(dataString:String):void{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE,loaded);
			function loaded(e:Event){
				//trace("服务器返回的数据是:"+loader.data);
				ReciveData(loader.data);
			}
			var request:URLRequest = new URLRequest();
			var mydate = new Date();
			var minute = mydate.getMinutes();
 			var second = mydate.getSeconds();
 			_WebCount++;
			request.url = "http://5.littlesmallsu.sinaapp.com/chessPlay.php?"
				+"time=" + minute+second + _WebCount
				+dataString;

			//trace("对服务器发送的请求是："+request.url);

			request.method = URLRequestMethod.GET;

			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.load(request);
		}

		//接收到服务器返回的数据
		function ReciveData(jsonString:String):void {
			//解析字符串
			var jsonArray:Array = com.adobe.serialization.json.JSON.decode(jsonString);
			//打印结果
			//trace("服务器下棋步数" + jsonArray.length);
			//trace("本地下棋步数"+crtNum);

			if (crtNumWeb != jsonArray.length) {
				trace("服务器下棋步数" + jsonArray.length);
				trace("本地下棋步数"+crtNum);
			}
			crtNumWeb = jsonArray.length;

			//如果当前的步数小于服务器的步数,就更新到最新的那步
			if (crtNum < jsonArray.length) {
				canPlay = false;
				//添加步数
				crtNum++;
				btnStart.visible = false;
				//查找需要更新的那一步
				for each(var go in jsonArray) {
					if(go.s == crtNum){
						trace("添加记录到本地 步数：" + go.s+" 下棋方：" + go.c + " x：" + go.x + " y：" + go.y);
						AddChessman(int(go.x), int(go.y), int(go.c));
					}
				}
			}else{
				canPlay = true;
			}

			//初始化
			if(jsonArray.length == 0){
				//初始化棋盘
				init();
				//隐藏开始游戏的按钮
				canPlay = true;
				btnStart.visible = false;
				crtNum = 1;
			}
		}
	}
}
