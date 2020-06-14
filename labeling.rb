# coding: utf-8
require 'via/gfc'

=begin

** Flood Fillによるラベリング

グレイスケール画像と閾値が与えられたときに，閾値未満の輝度値の領域が
前景(物体領域)であるとして，ラベリング処理を行う．

* 実行方法:
  ruby このファイルの名前 画像ファイル 閾値

=end

# 2値画像gとラベル配列labelを使って(x,y)を含む物体領域全体に対して
# 配列labelにラベル番号cをつける
# g: 画像
# label: ラベル配列
# (x0,y0): ラベルをつけ始める最初のピクセルの位置
# c: 付与するラベル
def flood_fill(g,label,x0,y0,c)
  # front: 最前線(ラベルをつけた領域とつけてない領域の境界)上の点の列
  # (front=[[x0,y0],[x1,y1],....]のように点の列を格納しておく)
  # 最初は開始点のみを入れておく
  front = [[x0,y0]] 
  label[x0,y0] = c # 開始点(x0,y0)にまずラベルcをつける

  # 「最前線の周囲にラベルをつけて最前線を更新する」処理を
  # 最前線がなくなるまで(=最前線がある限り)繰り返す．
  while front != [] # ← 「最前線の点がある」という条件に書き換える
    x,y = front.shift # 最前線の点の列から先頭を取り出す
    g.each_neighbor(x,y) do |px,u,v|
	z = px.i
	if z == 0 and label[u,v] == 0
	label[u,v] = c
	front.push([u,v])
	end	
      # 黒で(u,v)にラベルがなければ(ラベル=0ならば)  
      # (u,v)にラベルcをつけて，(u,v)を最前線に加える
    end
  end
end

## 画像と閾値が与えられていることの確認
if ARGV.size < 2
  STDERR.puts "#{File.basename($0)} image threshold"
  exit 1
end

iname = ARGV.shift  # 画像ファイル名
t = ARGV.shift.to_i # 閾値

# 閾値が適切かどうかの確認
if t < 1 or 255 < t
  STDERR.puts "should give a threshold value in [1,255]"
  exit 2
end

# 画像の読み込みとグレイスケールかどうかの確認
gin = Gfc.load(iname)
if gin.color_space != Gfc::COLOR_GRAY
  STDERR.puts "grayscale image is expected"
  exit 3 
end

# 画像サイズの取得
w,h = gin.size 

# 境界の処理を簡単にするため，
# g = (w+1)x(h+1)の画像として生成して，
# ginを二値化した結果をgに格納する
# (右端と下端の縁は白になる)
# g[i,j]で(i,j)の位置のピクセルを参照できる
# (i,j)は画像の幅と高さの剰余類で解釈される
# (左右と上下がそれぞれつながっていると解釈できる)
#
# g[i,j]で0 <= i < w,0 <= j < hの範囲は画像に対応する
# g[-1,j]は右端のピクセルを指定することになる(白が得られる)
# g[i,-1]は下端のピクセルを指定することになる(白が得られる)
# ラベリングの対象が黒ピクセルだとすればこれで自然に境界の
# 処理ができる．
g = Gfc.new(w+1,h+1,Gfc::COLOR_GRAY)
[w,h].grid do |i,j|
  g[i,j] = (gin[i,j].i < t) ? 0 : 255
end

# ラベル配列の確保(w+1)x(h+1)
# すべて0にしておく．
# (i,j)の位置のピクセルに対応するラベル番号をlabel[i,j]に
# 格納しておく．このi,jも幅と高さの剰余類で解釈される
# label[i,-1]は下端の列を参照することになる(画像に対応しないdummy)
# label[-1,j]は右端の列を参照することになる(画像に対応しないdummy)
# こうすることでやはり画像と同様に境界の処理を簡単にできる．
# ラベル番号==0は背景，1以上の番号は物体に割り当てる
label = Array2D.new(w+1,h+1,0)

# 時間計測の起点の設定
__start = Time.now

## 画像，ラベルのスキャン
## 上から順に横列を左から右にスキャンする
c = 1 # ラベル番号
[w,h].grid do |i,j|
  # px=画像の(i,j)の位置の画素
  px = g[i,j]
  # ラベルがついていない物体領域を発見した
  if px.i == 0 and label[i,j] == 0 
    # 発見した物体領域全体にラベルcをつける
    flood_fill(g,label,i,j,c)
    c += 1 # 次のラベル番号の準備(c=c+1)
  end
end
# 見つかった物体の個数の表示
STDERR.puts "objects=#{c-1}"

# 処理時間の表示
elapse=Time.now-__start
STDERR.puts "#{elapse} sec"


#-------------------------------------------------------------
# ラベル画像生成と表示
#-------------------------------------------------------------

# ラベルに対する色割り当て-->ランダムに割り当てる
# ラベル0(背景)の色として[255,255,255]を入れておく
color=[[255,255,255]] 
count = c
1.upto(count-1) do 
  c = nil
  loop do 
    c = [rand(256),rand(256),rand(256)]
    break unless color.include?(c)
  end
  color.push(c.dup)
end

## 割り当てた色に従ってラベル画像を生成する
gout = Gfc.new(w,h,Gfc::COLOR_COLOR)
[w,h].grid do |i,j|
  if label[i,j] > 0
    gout[i,j] = color[label[i,j]]
  end
end

# 処理時間の表示
elapse=Time.now-__start
STDERR.puts "#{elapse} sec"

# ラベル画像の表示(あるいは保存)
gout.save(ARGV.shift)
