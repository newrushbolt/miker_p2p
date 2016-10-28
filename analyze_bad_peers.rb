$my_dir=File.expand_path(File.dirname(__FILE__))
$my_id=ARGV[0] ? ARGV[0] : 1
$my_name="#{File.basename(__FILE__,".rb")}_#{$my_id}"
$my_type=$my_name.sub(/\.worker.*/,"")

require 'etc'
require 'mysql2'
require 'bunny'
require 'rubygems'
require 'logger'
require 'json'
require 'geoip'
require 'ipaddr'

require "#{$my_dir}/etc/common.conf.rb"
if File.exists?("#{$my_dir}/etc/#{$my_name}.conf.rb")
	require "#{$my_dir}/etc/#{$my_name}.conf.rb"
end

if $default_user and RUBY_PLATFORM.include?('linux')
    begin
        proc_user=Etc.getpwnam($default_user)
        Process::Sys.setuid(proc_user.uid)
    rescue => e
        raise "Error while changing user to #{$default_user}, #{e.to_s}"
    end
end

$err_logger=Logger.new("#{$my_dir}/var/log/#{$my_name}.log")
$err_logger.info "Launched #{$my_name}"
$err_logger.level=$log_level
if ARGV[1]
    case ARGV[1]
    when "debug"
	$err_logger.level=Logger::DEBUG
    when "info"
	$err_logger.level=Logger::INFO
    when "warn"
	$err_logger.level=Logger::WARN
    when "error"
	$err_logger.level=Logger::ERROR
    when "fatal"
	$err_logger.level=Logger::FATAL
    end
end

begin
	require $whois_lib
	$slow_whois=Slow_whois.new
	require "#{$my_dir}/#{$validate_lib}"
	$validator=Webrtc_validator.new	
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while loading libs"
end

$geocity_client=GeoIP.new('var/geoip/GeoLiteCity.dat')

begin
	$p2p_db_client=Mysql2::Client.new(:host => $p2p_db_host, :database => $p2p_db, :username => $p2p_db_user, :password => $p2p_db_pass)
rescue => e_main
	$err_logger.error e_main.to_s
	raise "Error while connecting to MySQL"
end

begin
		req="select INET_NTOA(ip) as ip from ip_bad_peers limit 1;"
		res=$p2p_db_client.query(req)
	rescue  => e
		$err_logger.error "Error in SQL insert for #{peer["webrtc_id"]}"
		$err_logger.error peer
		$err_logger.error e.to_s
		$err_logger.error req
		return false
	end
puts res.inspect
	
res.each do |peer|
	puts "\nGot peer :\t#{peer}"
	aton_info=$slow_whois.get_ip_route(peer["ip"])
	if ! aton_info or aton_info.nil? or !(aton_info["network"] and aton_info["netmask"] and aton_info["asn"])
		puts "Not full"
	end
	puts aton_info
end