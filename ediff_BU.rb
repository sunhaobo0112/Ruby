require 'via/gfc'

BU = [[0,0,0,4,2],
      [1,2,4,2,1]]

W = BU.inject(0){ |s,x| s+x.inject(0){ |t,y| t+y}}

gin = Gfc.load(ARGV.shift)
exit 1 unless gin.color_space == Gfc::COLOR_GRAY

w,h = gin.size
gout = Gfc.new(w,h,Gfc::COLOR_GRAY)

buff = ScanningBuffer.new(gin,BU)
buff.load

s = 1
t = 2

h.times do |j|

  i = (s == 1) ? 0 : w-1
  w.times do

  u = buff[i,j]
  gout[i,j] = v = (u < 128) ? 0 : 255

  err = u - v
  buff[i+s,j]        += (err*BU[0][3]/W)
  buff[i+t,j]         += (err*BU[0][4]/W)
  buff[i-t,j+1]      += (err*BU[1][0]/W)
  buff[i-s,j+1]     += (err*BU[1][1]/W)
  buff[i,j+1]        += (err*BU[1][2]/W)
  buff[i+s,j+1]    += (err*BU[1][3]/W)
  buff[i+t,j+1]     += (err*BU[1][4]/W)
  i += s
end

buff.push

s = -s
end

gout.save(ARGV.shift)
