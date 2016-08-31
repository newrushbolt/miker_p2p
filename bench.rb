require "#{Dir.pwd}/config.rb"
require 'logger'
require 'rubygems'
require 'whois'
require 'geoip'
require 'benchmark'

def get_aton_info(aton)
		info_result = {}
		whois_client = Whois::Client.new
		begin
			aton_ip=IPAddr.new(aton)
			whois_result= whois_client.lookup(aton).to_s
		rescue  => e
			$err_logger.error "Error while geting #{aton} info"
			$err_logger.error e.to_s
			return nil
		end
		if whois_result and 
			whois_result.split("\n").each do |whois_result_line|
				if whois_result_line.start_with?("origin")
					info_result[:asn]=whois_result_line.gsub(/^origin\:[w| ]*(AS|as|As|aS)/, "")
				end
				if whois_result_line.start_with?("CIDR")
					info_result[:network]=whois_result_line.gsub(/^CIDR\:[w| ]*/, "")
				end
				if whois_result_line.start_with?("netname")
					info_result[:netname]=whois_result_line.gsub(/^netname\:[w| ]*/, "")
				end
				if whois_result_line.start_with?("NetName")
					info_result[:netname]=whois_result_line.gsub(/^NetName\:[w| ]*/, "")
				end
				if whois_result_line.start_with?("route")
					info_result[:network]=whois_result_line.gsub(/^route\:[w| ]*/, "")
				end
			end
		end
		return info_result
end

res={}
bnch=Benchmark.measure {res=get_aton_info("8.8.8.8")}
puts res.to_s
puts bnch.to_s


