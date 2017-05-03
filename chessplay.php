<?php

// http://5.littlesmallsu.sinaapp.com/chessPlay.php?ini=1
// http://5.littlesmallsu.sinaapp.com/chessPlay.php?x=1&y=1&c=1

header("Content-type:text/html;charset=utf-8");

//初始化
if ( isset($_REQUEST['ini'])) {
	deleteChess();
	$c = new SaeCounter();
	$c->set('chessStep',1);
}
//刷新下棋位置
if (isset($_REQUEST['x']) && isset($_REQUEST['y']) && isset($_REQUEST['c'])) {
	$tmp['c']=$_REQUEST['c'];
	$tmp['x']=$_REQUEST['x'];
	$tmp['y']=$_REQUEST['y'];

	$c = new SaeCounter();
	$tmp['s']=$c->get('chessStep');
	insertChess($tmp);

	$c->incr('chessStep');
}
//显示所有下棋
selectChess();


//函数部分
function insertChess($tmp){
	$kv = new SaeKV();
	$ret = $kv->init();
	$ret = $kv->set('chess_'.$tmp['s'], $tmp);
}
function deleteChess(){
	$kv = new SaeKV();
	$kv->init();
	$ret = $kv->pkrget('chess_', 100);

	foreach ($ret as $key => $value) {
		$ret = $kv->delete('chess_'.$value['s']);
	}
}
function selectChess(){
	$kv = new SaeKV();
	$kv->init();
	$ret = $kv->pkrget('chess_', 100);

	$_return ;
	foreach ($ret as $key => $value) {
		$_return[] = $value;
	}
	if (isset($_return)) {
		echo json_encode($_return);
	}
	else{
		echo "[]";
	}
}