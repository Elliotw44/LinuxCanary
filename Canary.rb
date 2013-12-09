# Canary.rb queries the local CGMiner for information about the miner.
# It then compiles that information into a JSON and sends a http PUT to Miners Canary
# It does this every 3 minutes so the websites information is real time

require 'socket'
require 'rest_client'
require 'json'
require 'rubyrems'
require 'rufus/scheduler'

user = ARGV[0]
worker = ARGV[1]

if(user != nil || worker != nil)
	#Error Checking on agruments
	numbers_re = /^\d+$/
	u = number_re.match(user)
	unless u
		puts "Your username must be all numbers."
		exit
	end
	if(worker.length > 2)
		puts "Your workername should be only 2 characters long"
		exit
	end
	
	#Updater
 	scheduler.every '3m' do
		worker_user_name = "#{user}:#{worker}"

    	#Getting General Information about Miner
		s = TCPSocket.new '127.0.0.1', 4028
		s.puts '{"command":"summary"}'
		summary_query = s.gets
		summary_query.strip! 
		parsed = JSON.parse(summary_query)
		summary = parsed["SUMMARY"]
		summary = summary[0]
		accepted = summary["Accepted"]
		rejected = summary["Rejected"]
		hw_errors = summary["Hardware Errors"]

    	#Getting GPU information(Speed and Tempature)
		s = TCPSocket.new '127.0.0.1', 4028
		s.puts '{"command":"gpucount"}'
		gpucount_query = s.gets
		gpucount_query.strip!
		parsed = JSON.parse(gpucount_query)
		gpucount = parsed["GPUS"]
		gpucount = gpucount[0]
		gpucount = gpucount["Count"]
		gpus = Array.new(gpucount * 2)
		gpucount.times do |num|   
   			s = TCPSocket.new '127.0.0.1', 4028
   			s.puts '{"command":"gpu|' + num.to_so + '" }'
   			gpu_query = s.gets.strip!
   			gpu_parsed = JSON.parse(gpu_query)
   			gpus[num] = gpu_parsed[0]["Tempature"]
   			num += 1
   			gpus[num] = gpu_parsed[0]["MHS 5s"]
		end

    	#Creating and sending JSON 
		updateinfo = { wun: worker_user_name, a: accepted, r: rejected, he: hw_errors, gs: gpus }
		path = "/workers/update"
		host = "https://cryptocanary.herokuapp.com"
		puts RestClient.put "#{host}#{path}", updateinfo, {:content_type => :json} 
	end
else
	puts "Incorrect agruments passed to Canary monitoring system.\n"
	puts "Example: Canary.rb userid  workername"
end

