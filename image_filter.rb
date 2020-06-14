# -*- mode: ruby; coding: utf-8 -*-

require 'via/gfc'
require 'via/filtering'
require 'optparse'

module Filter
  STDOUT_SYMBOL='-'
  
  # Emboss
  EMBOSS_KERNEL=[
    [-2,-1,0],
    [-1, 1,1],
    [ 0, 1,2]
  ]
  
  ## Laplacian-4
  LAPLACIAN_KERNEL=[
    [0,1,0],
    [1,-4,1],
    [0,1,0]
  ]
  
  # Sobel
  SOBEL=Array2D.new [
    [-1,0,1],
    [-2,0,2],
    [-1,0,1]
  ]
  SOBEL_KERNEL= proc { |window,w,h|
    a,b = 0,0
    [3,3].grid do |i,j|
      u=window[i,j]
      a += u*SOBEL[i,j]
      b += u*SOBEL[j,i]
    end
    Math.sqrt(a*a+b*b).round
  }

  # Forsen
  FORSEN_KERNEL=Proc.new { |window,w,h|
    (window[1,1]-window[2,2]).abs+
      (window[2,1]-window[1,2]).abs
  }
  
  def self.configure_averaging(n)
    n += (1-n%2)
    kernel = Array.new(n) { Array.new(n,1) }
    option = { Gfc::FILTER_KERNEL_NORMALIZE=>true }
    [kernel,option]
  end
  
  def self.configure_median(n)
    n += (1-n%2)
    kernel = proc { |window,w,h|
      window.sort[w/2,h/2]
    }
    option = { Gfc::FILTER_KERNEL_SIZE=>[n,n] }
    [kernel,option]
  end
  
  def self.configure_gaussian(sigma)
    kernel=Gaussian.kernel(sigma)
    option = {}
    [kernel,option]
  end
  
  def self.configure_range(n)
    n += (1-n%2)
    kernel= proc { |window,w,h|
      min,max = window.minmax
      max-min
    }
    option = { Gfc::FILTER_KERNEL_SIZE=>[n,n] }
    [kernel,option]
  end
  
  def self.configure_sobel
    kernel = SOBEL_KERNEL
    option = {
      Gfc::FILTER_IMAGE_RESCALE=>true,
      Gfc::FILTER_KERNEL_SIZE=>[3,3]
    }
    [kernel,option]
  end
  
  def self.configure_laplacian
    kernel = LAPLACIAN_KERNEL
    option = {
      Gfc::FILTER_IMAGE_RESCALE=>true,
      Gfc::FILTER_KERNEL_SIZE=>[3,3]
    }    
    [kernel,option]
  end
  
  def self.configure_forsen
    kernel = FORSEN_KERNEL
    option = {
      Gfc::FILTER_IMAGE_RESCALE=>true,
      Gfc::FILTER_KERNEL_SIZE=>[3,3]
    }    
    [kernel,option]
  end

  def self.configure_emboss
    kernel = EMBOSS_KERNEL
    option = {
      Gfc::FILTER_IMAGE_RESCALE=>true
    }    
    [kernel,option]
  end
end

opts = { }
ARGV.options { |opt|
  opt.banner = "Usage: ruby #{File.basename($0)} [options] in_image [out_image]"
  opt.summary_width = 5
  opt.on('-a n','averaging by nxn window') { |v| opts[:config] = [:configure_averaging,v.to_i] } 
  opt.on('-m n','median filter by nxn window') { |v| opts[:config] = [:configure_median,v.to_i] } 
  opt.on('-g s','gaussian filter with sigma=s') { |v| opts[:config] = [:configure_gaussian,v.to_f] } 
  opt.on('-r n','range filter by nxn window') { |v| opts[:config] = [:configure_range,v.to_i] } 
  opt.on('-s','sobel filter') { opts[:config] = [:configure_sobel] } 
  opt.on('-l','laplacian filter') { opts[:config] = [:configure_laplacian] } 
  opt.on('-f','forsen filter') { opts[:config] = [:configure_forsen] } 
  opt.on('-e','emboss filter') { opts[:config] = [:configure_emboss] } 

  opt.parse!
  if ARGV.size == 0 || !opts[:config]
    STDERR.puts opt.help
    exit 1
  end
}
gin = Gfc.load(ARGV.shift)
gout=Filter.filter(gin,opts[:config])

outname=ARGV.shift
outname = STDOUT if outname == Filter::STDOUT_SYMBOL
gout.save(outname)



