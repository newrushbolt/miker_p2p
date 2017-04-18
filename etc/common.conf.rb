$log_level=Logger::INFO
$default_user='svmikhailov'

$p2p_db='p2p'
$p2p_db_host='127.0.0.1'
$p2p_db_user='p2p'
$p2p_db_pass='wb5nv6d8'
$p2p_db_state_table='peer_state'
$p2p_db_peer_load_table='peer_load_5'
$p2p_db_bad_peer_table='peer_bad_30'
$p2p_db_counters_table='worker_counters'
$p2p_db_online_peers_table='online_peers'
$p2p_db_peer_lists_table='peer_lists'

$rabbit_host='127.0.0.1'
$rabbit_port='5672'

$validate_lib='lib/validate.lib.rb'

$whois_lib='../fast_route_whois/lib/whois.lib.rb'
$make_peer_list_start_port=3500
$seed_max_drops_30=30
$seed_max_peers_5=15

$private_nets=["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16","127.0.0.0/8", "169.254.0.0/16","224.0.0.0/4","240.0.0.0/4"]
$rr_urls=['ftp://ftp.ripe.net/ripe/dbase/split/ripe.db.route.gz',
'ftp://ftp.arin.net/pub/rr/arin.db',
'ftp://ftp.apnic.net/public/apnic/whois/apnic.db.route.gz',
'ftp://ftp.afrinic.net/dbase/afrinic.db.gz']

def cnt_up(worker,type)
	begin
		req="update #{$p2p_db_counters_table} set count = count + 1 where worker=\"#{worker}\" and type=\"#{type}\";"
		$err_logger.debug req
		res=$p2p_db_client.query(req)
		return true
	rescue  => e
		$err_logger.error "Error in SQL counters update for #{worker} type #{type}"
		$err_logger.error req
		$err_logger.error e.to_s
		return false
	end
end

def cnt_init(worker)
	["failed","success","invalid"].each do |field|
		begin
			req="insert ignore into #{$p2p_db_counters_table} values (\"#{worker}\",\"#{field}\",0);"
			$err_logger.debug req
			res=$p2p_db_client.query(req)
		rescue  => e
			$err_logger.error "Error in SQL init counters #{worker} type #{field}"
			$err_logger.error req
			$err_logger.error e.to_s
		end
	end
end


#May need it later
#$ripe_prefix_url='https://stat.ripe.net/data/announced-prefixes/data.json?'
#$ripe_as_con_url='https://stat.ripe.net/data/as-routing-consistency/data.json?'
