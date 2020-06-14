# -*- mode: ruby; coding: utf-8 -*-

require 'via/gfc'

# 処理対象画像を読み込む→ginと名付ける
gin = Gfc.load(ARGV.shift)

# 画像ginのサイズ(w×h)の取得(w=横方向，h=縦方向の画素数)
w,h = gin.size
# 出力画像(カラー)を用意→goutと名付ける
gout = Gfc.new(w,h,Gfc::COLOR_GRAY)

# w×hのすべての格子点(i,j)に対して同一の処理
# を行って，画像goutの画素(i,j)の値を決める．
# この場合は，赤成分のみを取り出す．
[w,h].grid do |i,j|
  # gin[i,j]: ginの画素(i,j)
  # gout[i,j]: goutの画素(i,j)
  x = gin[i,j] # ginの画素(i,j)→xと名付ける
  # goutの画素(i,j)の値を設定する
  y = (0.299*x.r + 0.587*x.g + 0.114*x.b).round
  gout[i,j] = y # x.r: xの赤成分
end
gout.save(ARGV.shift)
