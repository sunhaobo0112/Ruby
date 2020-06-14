# -*- mode: ruby; coding: utf-8 -*-
require 'via/gfc'
require 'via/labeling'
require 'via/threshold'
require 'via/fext'
require 'via/kmeans++'
require 'pp'

include FExtractorConst

# 面積(物体に属する点の個数)を得る処理関数
AREA_PROC = proc { |f,v| v+1}

# 外接矩形[x_min,x_max,y_min,y_max]を得る処理関数
# 物体を囲う最小の長方形のデータ
BB_PROC = proc { |f,v|
  x,y = f.pos
  v[0] = x if x < v[0] # x_min
  v[1] = x if x > v[1] # x_max
  v[2] = y if y < v[2] # y_min
  v[3] = y if y > v[3] # y_max
  v
}
# 外接矩形→縦横比を計算する関数
BB_POST = proc { |f,v|
  dx = (v[1]-v[0])+1
  dy = (v[3]-v[2])+1
  dy.to_f/dx # dx > 0
}

INFINITY=1.0/0 # Infinity
# 特徴量のデータ
FITEM=[
       # 名称，処理関数，処理関数に渡す初期値，後処理関数,特徴量の正規化の指定
       [:area,AREA_PROC,0,nil,NORMALIZE_DISTRIBUTION],
       [:aspect,BB_PROC,[INFINITY,-INFINITY,INFINITY,-INFINITY],BB_POST,NORMALIZE_DISTRIBUTION],
      ]

if ARGV.size < 2
  STDERR.puts "#{File.basename($0)} image #clusters"
  exit 1
end

#--------------------------------------------------------------
# 引数読み取り
#--------------------------------------------------------------
iname = ARGV.shift  # 画像ファイル名
K = ARGV.shift.to_i # クラスタ数

#--------------------------------------------------------------
# 画像の読み込みとラベリング
#--------------------------------------------------------------
# label[i,j]==0 背景
# label[i,j]==m 物体No.m(m > 0)
# count = 物体の個数
gin = Gfc.load(iname)
w,h = gin.size
t = gin.threshold
label,count=gin.labeling(t)
STDERR.puts "size=#{w}x#{h}"
STDERR.puts "objects=#{count}"
# 物体が一つもなければ終了
exit 0 if count == 0

#--------------------------------------------------------------
# 特徴ベクトルの構築
# (正規化した面積と正規化した縦横比を特徴ベクトルにとる)
#--------------------------------------------------------------

# ラベリングされた物体のそれぞれについて，
# 特徴量データ(FITEM)に従って，特徴量抽出器を構築する
lmap=LabelMap.new(label,w,h,count)
fext=FExtractor.configure(lmap,FITEM)

# 各物体の特徴ベクトルの抽出
# 0=>背景, 1,2,...,count=>物体
v=fext.extract

# クラスタ数=0が与えられたときは，特徴ベクトルを出力して終了する
if K == 0
  1.upto(count) do |i|
    # i番の物体の特徴ベクトルの表示
    print "no.#{i} "
    pp v[i] 
  end
  exit 0
end

#--------------------------------------------------------------
# クラスタリング
#--------------------------------------------------------------

# クラスタリング kls[i]はi番めのデータのクラスタ番号(0...k-1)
v.shift # 背景(0番の物体のデータ)を排除する
kls = KMeansPP.clustering(v,K)
kls.unshift(nil) # 背景(0番の物体)のクラスタ番号をnilとする

#--------------------------------------------------------------
# クラスタリングの結果を画像表示する
#--------------------------------------------------------------

# 物体0の色はdummyで[255,255,255]を入れておく
# (白以外をcolormapに入れるため)
color=[[255,255,255]] 
K.times do 
  c = nil
  loop do 
    c = [rand(256),rand(256),rand(256)]
    break unless color.include?(c)
  end
  color.push(c.dup)
end

gout = Gfc.new(w,h,Gfc::COLOR_COLOR)
h.times do |j|
  w.times do |i|
    q = label[i,j]
    # cluster番号(0..k-1)+1の色
    gout[i,j] = color[kls[q]+1] if q > 0
  end
end

gout.save(ARGV.shift)
