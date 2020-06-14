require 'via/gfc'

gin=Gfc.load(ARGV.shift)

w,h = gin.size

gout = Gfc.new(w,h,Gfc::COLOR_GRAY)

exit 1 unless gin.color_space == Gfc::COLOR_GRAY

y_min = gin.ymin
y_max = gin.ymax

[w,h].grid {|i,j|

 y_in = gin[i,j].i

 y_out = (y_in - y_min) * (256/(y_max - y_min)) + 1

 gout[i,j] = y_out
}

gout.view
#gout.save(ARGV.shift)
