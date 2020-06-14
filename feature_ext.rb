# -*- coding: utf-8 -*-
require 'via/gfc'
require 'via/labeling'
require 'via/threshold'
require 'via/fext'
require 'pp'

# 面積(物体に属するピクセルの個数)を得る処理関数
# f: 特徴抽出器
# c: 特徴量計算用データ(スキャン済みの範囲で見つけたピクセルの個数)
AREA_PROC = proc { |f,c| 
  v = c + 1 # 新たに見つかったピクセル1個分で値を更新する
  v # 関数の末尾に記述した値に特徴量計算用データが更新される
}

# 外接矩形[x_min,x_max,y_min,y_max]を得る処理関数
# 物体を囲う最小の長方形のデータ
# f: 特徴抽出器
# b: 特徴量計算用データ(スキャン済みの範囲で計算された外接矩形のデータ)
#    b=[x_min,x_max,y_min,y_max]
BB_PROC = proc { |f,b|
  x,y = f.pos
  # 新たに見つかったピクセルの位置(x,y)をつかって
  # 外接矩形を更新する
  v = b.dup
  v[0] = x if x < b[0] # x_min
  v[1] = x if x > b[1] # x_max
  v[2] = y if y < b[2] # y_min
  v[3] = y if y > b[3] # y_max
  v # 関数の末尾に記述した値に特徴量計算用データが更新される
}

# 物体の個数(ラベリング後に値が代入される)
count = 0

# 物体の境界線の長さ(境界上のピクセル数)を得る処理関数
# f: 特徴抽出器
# c: 特徴量計算用データ(スキャン済みの範囲で見つけた境界上のピクセルの個数)
B_PROC = proc { |f,c|
  # label: ラベルmap (label[i,j])
  # x,y:   現在調べているピクセルの位置
  x,y = f.pos
  label = f.label
  # ここで現在調べているピクセル(x,y)が境界上にあるかどうかを判定して，
  # 境界上であれば，cに1を加えた値で情報を更新する処理を行う
  # (境界上にあるピクセル＝背景のピクセルと少なくとも1辺で接している)
  # 境界上にあるかどうかは周囲のlabelを調べて判定する
  # label[x,y] = 現在調べているピクセルのラベル
  # ピクセル(i,j)が背景⇔label[i,j]=0
 
  # (x,y)が境界上にある場合
  # falseを「(x,y)が境界上にある」という条件に書き換える
  if label[x-1,y]!=0 || label[x,y-1]!=0 || label[x+1,y]!=0 || label[x,y+1]!=0
    v = c + 1
     #label[x,y]=count+1 # この行を有効にすると、境界に色をつけられる
  else # (x,y)が境界上ではなかった場合は値は更新しない．
    v = c
  end
  v # 関数の末尾に記述した値に特徴量計算用データが更新される
}

INFINITY=1.0/0 # Infinity
# 特徴量のデータ
FITEM=[
       # 名称，処理関数，処理関数に渡す初期値，[後処理関数]
       [:area,AREA_PROC,0],
       [:bb,  BB_PROC,[INFINITY,-INFINITY,INFINITY,-INFINITY]],
       [:boundary, B_PROC,0],
      ]

if ARGV.size == 0
  STDERR.puts "#{File.basename($0)} image"
  exit 1
end

# 画像の読み込みとサイズの取得
iname = ARGV.shift
g = Gfc.load(iname)
w,h = g.size
t = g.threshold # 閾値の決定

STDERR.puts "image size=#{w}x#{h}"
STDERR.puts "threshold=#{t}"

# 閾値tで二値化して，黒の連結成分を物体としてラベリングする
label,count=g.labeling(t)
STDERR.puts "#objects=#{count}"

# 物体が一つもなければ終了
exit 0 if count == 0

# ラベリングされた物体のそれぞれについて，
# 特徴量データ(FITEM)に従って，特徴を抽出する
result=FExtractor.extract(LabelMap.new(label,w,h,count),
                        FITEM,FExtractor::FV_AS_NAMED_LIST)

# ラベル画像の生成
gout,cmap = Gfc.label_image(label,true)

# 特徴量とラベル画像での物体の色を物体番号順に出力する(ただし0=背景)
result.each_with_index do |item,i|
  print "#{i} "
  pp [:feature,item,[:color,cmap[i]]]
end

# ラベル画像の表示
gout.save(ARGV.shift)
