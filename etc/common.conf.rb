$log_level=Logger::INFO
$default_user='mihailov.s'

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
$counters_lib='lib/counters.lib.rb'

$whois_lib='../fast_route_whois/lib/whois.lib.rb'
$make_peer_list_start_port=3500
$seed_max_drops_30=30
$seed_max_peers_5=15

$private_nets=["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16","127.0.0.0/8", "169.254.0.0/16","224.0.0.0/4","240.0.0.0/4"]

#May need it later
#$ripe_prefix_url='https://stat.ripe.net/data/announced-prefixes/data.json?'
#$ripe_as_con_url='https://stat.ripe.net/data/as-routing-consistency/data.json?'
