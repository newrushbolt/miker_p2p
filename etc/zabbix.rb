require 'json'

workers=File.read("/home/mihailov.s/miker_p2p/etc/init_sources.sh").encode('utf-8', :invalid => :replace, :undef => :replace)


data={"data" =>[]}
data2={"data" =>[]}
#puts workers.each_line.inspect

workers.split("\n").each do |line|
    arr=line.match(/^.*_WORKERS=[0-9]*/)
    if ! arr.nil? and arr.to_s.split("=")[1].to_i > 0
	worker=arr.to_s.split("=")[0].sub("_WORKERS",".WORKER.RB").swapcase
	worker_cnt=arr.to_s.split("=")[1].to_i
	for i in (1..worker_cnt)
	    res={"{#WORKER}" => "#{worker} #{i}"}
	    data["data"].push(res)
	end
	res={"{#COUNTER}" => "#{worker.sub('.worker.rb','')}"}
	data2["data"].push(res)
    end
end

workers_data=JSON.pretty_generate(data)
counters_data=JSON.pretty_generate(data2)
File.write("/etc/zabbix/data/candy_workers.json",workers_data)
File.write("/etc/zabbix/data/candy_counters.json",counters_data)
