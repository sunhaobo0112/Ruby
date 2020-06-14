require 'via/gfc'

gin=Gfc.load(ARGV.shift)

exit 1 unless gin.color_space == Gfc::COLOR_GRAY

t = ARGV.shift.to_i

w,h = gin.size

gout = Gfc.new(w,h,Gfc::COLOR_GRAY)

[w,h].grid {|i,j|

 y_in = gin[i,j].i

 y_out = (y_in >= t)? y_in : 0

 gout[i,j] = y_out
}

gout.view
#gout.save(ARGV.shift)
