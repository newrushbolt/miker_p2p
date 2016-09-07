require "#{Dir.pwd}/make_peer_list.lib.rb"

$my_name='make_peer_list.demon.rb'
$out_logger=Logger.new("#{$log_dir}/#{$my_name}.out.log")
$out_logger.info "Launched #{__FILE__} with #{ARGV.to_s}"

  resp=make_peer_list([ARGV[0],ARGV[1],ARGV[2]])
  $out_logger.info ARGV.to_s
  $out_logger.info resp
  puts resp
