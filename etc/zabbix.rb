require 'json'

workers=File.read("/home/mihailov.s/miker_p2p/etc/init_sources.sh").encode('utf-8', :invalid => :replace, :undef => :replace)


data={"data" =>[]}

#puts workers.each_line.inspect

workers.split("\n").each do |line|
    arr=line.match(/^.*_WORKERS=[0-9]*/)
    if ! arr.nil?
	worker=arr.to_s.split("=")[0].sub("_WORKERS",".WORKER.RB").swapcase
	worker_cnt=arr.to_s.split("=")[1].to_i
	for i in (1..worker_cnt)
	    res={"{#WORKER}" => "#{worker} #{i}"}
	    data["data"].push(res)
	end
    end
end

puts JSON.pretty_generate(data)
