#! /usr/bin/env ruby
# -*- mode: ruby; coding: utf-8 -*-
require 'via/gfc'

if ARGV.size < 2
  STDERR.puts "#{File.basename($0)} image0 image1"
  exit 1
end

g0=Gfc.load(ARGV.shift)
g1=Gfc.load(ARGV.shift)
unless g0.color_space  == g1.color_space
  STDERR.puts "a pair of images in the same colorspace is expected"
  exit 2
end

w,h = g0.size
w1,h1 = g1.size

unless (w==w1 and h==h1)
  STDERR.puts "a pair of images in the same size is expected"
  exit 3
end

count = 0
if g0.color_space == Gfc::COLOR_COLOR
  gout=Gfc.new(w,h,Gfc::COLOR_COLOR)
  [w,h].grid do |i,j|
    px0 = g0[i,j]
    px1 = g1[i,j]
    px0.r = (px0.r-px1.r).abs
    px0.g = (px0.g-px1.g).abs
    px0.b = (px0.b-px1.b).abs
    gout[i,j] = px0
    count += 1 if (px0.r + px0.g + px0.b > 0)
  end
else
  gout=Gfc.new(w,h,Gfc::COLOR_GRAY)
  [w,h].grid do |i,j|
    y0 = g0[i,j].i
    y1 = g1[i,j].i
    y = (y0-y1).abs
    gout[i,j] = y
    count += 1 if y > 0
  end
end
STDERR.puts "diff=#{count}/#{w*h}"
gout.view if count > 0
