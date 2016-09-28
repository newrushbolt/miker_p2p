require 'json'

workers_num=ARGV[0]?ARGV[0]:4

data={"data" =>[]}
for i in 1..workers_num.to_i
    line={"{#WORKER}" => i.to_s}
    data["data"].push(line)
end

puts JSON.pretty_generate(data)