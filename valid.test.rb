$my_dir=File.expand_path(File.dirname(__FILE__))

require 'logger'
require 'ipaddr'
require "#{$my_dir}/etc/common.conf.rb"
require "#{$my_dir}/lib/validate.lib.rb"

validator=Webrtc_validator.new

puts validator.v_ip(ARGV[0]).inspect
