# -*- mode: ruby; coding: utf-8 -*-
require 'via/gfc' # 画像処理ライブラリの読み込み

g = Gfc.load(ARGV.shift) # 指定された画像ファイルの読み込み
g.view                   # 画像の表示
