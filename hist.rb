require 'via/gfc'

gin=Gfc.load(ARGV.shift)
exit 1 unless gin.color_space == Gfc::COLOR_GRAY

hist = gin.histogram

y_min = gin.ymin
y_max = gin.ymax

y_min.upto(y_max) do |i|
 puts "#{i} #{hist[i]}"
end

STDERR.puts "#{y_min}--#{y_max}"
