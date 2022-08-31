import java.util.*;

OthelloBoard ob;


int boardxmin = 80;
int boardxmax = 880;
int boardymin = 320;
int boardymax = 1120;
int split = 8;
int bradius = (boardymax-boardymin)/split/2-6;
int wradius = (boardymax-boardymin)/split/2-9;

int ME = -1;
int AI = 1;

void setup() {

  size(960, 1200);
  background(255);
  //frameRate(10);
  ob = new OthelloBoard();
}

void draw() {
  drawBoard(ob);
}

void mouseClicked() {
  int mx = mouseX;
  int my = mouseY;
  int px, py, id;
  if (boardxmin <= mx && mx <=boardxmax) {
    if (boardymin <= my && my <=boardymax) {
      px = (mx-boardxmin) / ((boardxmax-boardxmin)/split);
      py = (my-boardymin) / ((boardymax-boardymin)/split);
      id = py * split+px;
      if (canOkeru(ob, id,ME)) {    // マウスクリックするときは常に自分なので-1
        ob = shori(ob,id);
        ob.history.add(new Hist(id,ME));
        ob.turn = AI;
        if(isOkenai(ob)){
          skip(ob);
        }else{
          ob = aiDo(ob);
          drawBoard(ob);
        }
      }
    }
  }
  if(isOkenai(ob)){    //自分が置けないときにスキップ
    ob = skip(ob);
    if(isOkenai(ob)){    //相手も置けないとき
      //END
      ob = skip(ob);
      println("END");
      Count(ob);
      println("");
      println("----------------------");
      println("");
      println("HISTORY");
      for(int i=0; i<ob.history.size(); i++){
        println(ob.history.get(i).coord+" "+ob.history.get(i).turn);
      }
    }
  }
}



void Count(OthelloBoard ob){
  int meishi = 0;
  int zeroishi = 0;
  int mescore = 0;
  int aiscore = 0;
  for(int i=0; i<split*split; i++){
    if(ob.board[i] == ME){
      meishi++;
      mescore += ob.boardPoint[i];
    }else if (ob.board[i] == 0){
      zeroishi++;
    }else if(ob.board[i] == AI){
      aiscore += ob.boardPoint[i];
    }
  }
  println("ME:"+meishi+" AI:"+(split*split-meishi-zeroishi));
  println("ME score:"+mescore+" AI score:"+aiscore);
}


class OthelloBoard {
  int[] board;   // 盤面
  int turn;        //　誰の番か?
  int[] boardPoint;  // ボードの評価点
  ArrayList<Hist> history;  // 履歴
  OthelloBoard() {
    board = initBoard();
    turn = -1;  // プレイヤーが先手でAIが後手（そしてAIはしろ) -1がくろ　1がしろ
    boardPoint = loadPoint();
    history = new ArrayList<Hist>();
  }
}

boolean isOkenai(OthelloBoard ob){
  for(int ix=0; ix<split; ix++){
    for(int iy=0; iy<split; iy++){
      if(canOkeru(ob,ix+iy*split,ob.turn)){
        return false;
      }
    }
  }
  return true;
}

OthelloBoard skip(OthelloBoard ob){
  print("Skipped:");
  if(ob.turn==ME){
   println("ME"); 
  }else{
    println("AI");
  }
  ob.turn *= -1;
  return ob;
}
OthelloBoard shori(OthelloBoard ob , int place){
  ArrayList<Integer> ishi = new ArrayList<Integer>();
  ArrayList<Integer> tmpishi = new ArrayList<Integer>();
  
  int[] xindex = {+0,+0,+1,-1,+1,+1,-1,-1};  // たてポジ　たてネガ　よこポジ　よこネガ　ななめX+Y+　ななめX+Y-　ななめX-Y+　ななめX-Y-
  int[] yindex = {+1,-1,+0,+0,+1,-1,+1,-1};
  int px = place % split;  // x
  int py = place / split;    //y
  int turn = ob.turn;
  ///ここから裏返せるかの判定
  
  for(int vec=0; vec < xindex.length; vec++){  // 方向判定を一元化
    tmpishi = new ArrayList<Integer>();
    boolean endflag = false;
    for(int itr = 1; itr <= split; itr++){
      if(px + xindex[vec] * itr >= 0 && px + xindex[vec] * itr< split && py + yindex[vec] * itr>= 0 && py + yindex[vec] * itr< split && endflag == false){    //範囲外参照してないか?
        if (ob.board[(px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split] == turn * -1) {  //自分またはAIのターンじゃないほうの石
          tmpishi.add((px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split);
        } else if (ob.board[(px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split] == 0) {  //置かれてない
          tmpishi = new ArrayList<Integer>();
          endflag = true;
        } else if(ob.board[(px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split] == turn && tmpishi.size() <= 0){    //じぶんの味方の石が置かれておりなおかつ挟まれている敵の石の数が0ならころがせない
          tmpishi = new ArrayList<Integer>();
          endflag = true;
        }else if ( ob.board[(px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split] == turn && tmpishi.size() > 0) {    //じぶんの味方の石が置かれておりなおかつ挟まれている敵の石の数が1いじょうでOK
          for(int vol = 0; vol < tmpishi.size(); vol++){
            ishi.add(tmpishi.get(vol));
          }
          endflag = true;
        }
      }
    }
  }
  ishi.add(place);
  for(int i=0; i<ishi.size(); i++){
    ob.board[ishi.get(i)] = turn;
  }
  return ob;
}


OthelloBoard aiDo(OthelloBoard ob){
  ArrayList<Integer> AIokeru = new ArrayList<Integer>();
  for(int ix=0; ix<split; ix++){
    for(int iy=0; iy<split; iy++){
      if(canOkeru(ob,ix+iy*split,AI)){
        AIokeru.add(ix+iy*split);
      }
    }
  }
  println(AIokeru.size());
  if(AIokeru.size()>0){
    int rnd = (int) (Math.random()*AIokeru.size());
    ob.history.add(new Hist(AIokeru.get(rnd),AI));
    shori(ob,AIokeru.get(rnd));
  }
  Count(ob);
  ob.turn = ME;
  return ob;
}
boolean canOkeru(OthelloBoard o, int place, int turn ) {    // -1がくろ 1がしろ(-1が自分)
  if (o.board[place] != 0) {    // すでに置かれていたらだめ
    return false;
  } else {
    int reverseblocks = 0;    //反転可能数
    int[] xindex = {+0,+0,+1,-1,+1,+1,-1,-1};  // たてポジ　たてネガ　よこポジ　よこネガ　ななめX+Y+　ななめX+Y-　ななめX-Y+　ななめX-Y-
    int[] yindex = {+1,-1,+0,+0,+1,-1,+1,-1};
    int px = place % split;  // x
    int py = place / split;    //y
    
    ///ここから裏返せるかの判定
    
    for(int vec=0; vec < xindex.length; vec++){  // 方向判定を一元化
      int tmpblocks = 0;
      boolean endflag = false;
      for(int itr = 1; itr <= split; itr++){
        if(px + xindex[vec] * itr >= 0 && px + xindex[vec] * itr< split && py + yindex[vec] * itr>= 0 && py + yindex[vec] * itr< split && endflag == false){    //範囲外参照してないか?
          if (o.board[(px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split] == turn * -1) {  //自分またはAIのターンじゃないほうの石
            tmpblocks++;
          } else if (o.board[(px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split] == 0) {  //置かれてない
            tmpblocks = 0;
            endflag = true;
          } else if(o.board[(px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split] == turn && tmpblocks <= 0){    //じぶんの味方の石が置かれておりなおかつ挟まれている敵の石の数が0ならころがせない
            tmpblocks = 0;
            endflag = true;
          }else if ( o.board[(px + xindex[vec] * itr) + (py + yindex[vec] * itr) * split] == turn && tmpblocks > 0) {    //じぶんの味方の石が置かれておりなおかつ挟まれている敵の石の数が1いじょうでOK
            reverseblocks += tmpblocks;
            endflag = true;
          }
        }
      }
    }
    if (reverseblocks > 0) {
      
      return true;
    }
  }
  return false;
}

class Hist {
  int coord;  // 石を置いた座標
  int turn;    // 誰のターンか?
  Hist(int c, int t) {
    this.coord = c;
    this.turn = t;
  }
  int coord() {
    return this.coord;
  }
  int turn() {
    return this.turn;
  }
}
public int[] loadPoint() {    //盤面の評価値を読み取る
  int[] hyouka = new int[split*split];
  String[] ld = loadStrings("board.txt");
  for (int i=0; i<split; i++) {
    String[] tmp = ld[i].split(",");
    for (int j=0; j<split; j++) {
      hyouka[i*split+j] = Integer.parseInt(tmp[j]);
    }
  }
  return hyouka;
}

public int[] initBoard() {    //盤面初期化
  int[] res = new int[split*split];
  Arrays.fill(res, 0);
  
  //res[(split/2-1)*split+split/2-2]=1;  //ななめデバッグ
  
  
  res[(split/2-1)*split+split/2-1]=1;
  res[(split/2-1)*split+split/2]=-1;
  res[(split/2)*split+split/2-1]=-1;
  res[(split/2)*split+split/2]=1;
  return res;
}

public void drawBoard(OthelloBoard b) {    // ボード描画
  background(255);
  fill(0, 127, 0);
  rect(boardxmin, boardymin, boardxmax-boardxmin, boardymax-boardymin);
  int bxdif = (boardxmax-boardxmin);
  int bydif = (boardymax-boardymin);
  noStroke();
  for (int i=0; i<split*split; i++) {
    if (b.board[i] == -1) {
      fill(0);
      ellipse(boardxmin+bxdif/(split*2)+bxdif/split*(i%split), boardymin+bydif/(split*2)+bydif/split*(i/split), bradius*2, bradius*2);
    } else if (b.board[i] == 1) {
      fill(255);
      ellipse(boardxmin+bxdif/(split*2)+bxdif/split*(i%split), boardymin+bydif/(split*2)+bydif/split*(i/split), wradius*2, wradius*2);
    }
  }
  for(int ix=0; ix<split; ix++){
    for(int iy=0; iy<split; iy++){
      if(canOkeru(b,ix+iy*split,b.turn)){
        fill(255,255,255,127);
        noStroke();
        rect(boardxmin + ix * bxdif/split,boardymin + iy * bydif/split,bxdif/split,bydif/split);
      }
    }
  }
  strokeWeight(4);
  stroke(4);
   for (int i=1; i<=split-1; i++) {
    line(boardxmin+bxdif/split*i, boardymin, (width - bxdif ) /2+bxdif/split*i, boardymax);
    line(boardxmin, boardymin+bydif/split*i, boardxmax, boardymin+bydif/split*i);
  }
}


/*
プレイヤーから見た座標
 
 |00|01|02|03|04|05|06|07|
 |08|09|10|11|12|13|14|15|
 |16|17|18|19|20|21|22|23|
 |24|25|26|27|28|29|30|31|
 |32|33|34|35|36|37|38|39|
 |40|41|42|43|44|45|46|47|
 |48|49|50|51|52|53|54|55|
 |56|57|58|59|60|61|62|63|
 
 
 
 
 
 
 
 */
