$log_level=Logger::INFO
$default_user='mihailov.s'

$p2p_db='p2p'
$p2p_db_host='localhost'
$p2p_db_user='p2p'
$p2p_db_pass='wb5nv6d8'
$p2p_db_state_table='peer_state'

$whois_lib='../fast_route_whois/lib/whois.lib.rb'
$make_peer_list_start_port=3500


$private_nets=["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16","127.0.0.0/8", "169.254.0.0/16","224.0.0.0/4","240.0.0.0/4"]
$rr_urls=['ftp://ftp.ripe.net/ripe/dbase/split/ripe.db.route.gz',
'ftp://ftp.arin.net/pub/rr/arin.db',
'ftp://ftp.apnic.net/public/apnic/whois/apnic.db.route.gz',
'ftp://ftp.afrinic.net/dbase/afrinic.db.gz']


#May need it later
#$ripe_prefix_url='https://stat.ripe.net/data/announced-prefixes/data.json?'
#$ripe_as_con_url='https://stat.ripe.net/data/as-routing-consistency/data.json?'
