# -*- mode: ruby; coding: utf-8 -*-


=begin


誤差拡散法による二値化

誤差拡散の重み付け(右方向に進む場合)

Floyd-Steinberg
  * 7
3 5 1

=end

require 'via/gfc'

# Floyd-Steinberg
# FS: 誤差分配の比率のデータ、W:それらの総和
FS=[
  [0,0,7],
  [3,5,1]
]
W=FS.inject(0) { |rt,row| rt += (row.inject(0) { |r,x| r += x}) }

# グレイスケール画像の読み込みとサイズの取得
gin = Gfc.load(ARGV.shift)
exit 1 unless gin.color_space == Gfc::COLOR_GRAY

# 出力画像の確保
w,h = gin.size
gout = Gfc.new(w,h,Gfc::COLOR_GRAY)

# 作業用データ領域を(FSに合わせて)確保
buff = ScanningBuffer.new(gin,FS)
# buffに画像の最上段1列を読み込む
buff.load

s = 1 # 進行方向の指定（1=右向き,-1=左向き)

### 誤差拡散による2値化処理
h.times do |j| # h回繰り返す(j = 0,1,...,h-1)
  # 第j列の出力と誤差拡散
  i = (s == 1) ? 0 : w-1 # (i,j)=スキャン位置
  w.times do # w回繰り返す
    ## 2値化(0,255のうち近い方へ) ##########
    # 入力 u <  128 ==> 出力 v = 0
    # 入力 u >= 128 ==> 出力 v = 255
    u = buff[i,j] # (i,j)への入力値
    gout[i,j] = v = (u < 128) ? 0 : 255

    ## 誤差拡散 ############################
    err = u - v # 誤差: (入力値)-(出力値)
    buff[i+s,j]   += (err*FS[0][2]/W) # 7/16
    buff[i-s,j+1] += (err*FS[1][0]/W) # 3/16
    buff[i,j+1]   += (err*FS[1][1]/W) # 5/16
    buff[i+s,j+1] += (err*FS[1][2]/W) # 1/16
    i += s # 次に進む(iにsを加える)
  end
  buff.push  # 次に処理する画像の横列を読み込む
  s = -s     # 進行方向の反転(蛇行)
end
# 出力画像の保存あるいは表示
gout.save(ARGV.shift)
