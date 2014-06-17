require "open3"
require "json"

class MitmdumpReader

	def initialize(filename)
		@filename = filename
	end

	def get_requests_from_file
		read_from_flow_dump("-q")
	end

	def get_responses_from_file
		read_from_flow_dump("-s")
	end

	private

		def read_from_flow_dump(options="")
			cmd = "#{File.expand_path('../../bin', __FILE__)}/readFromFlow #{options << ' '}#{@filename}"
			pp cmd if $DEBUG
			Open3.popen3(cmd) do |_, o, e, w|
				@stdout = o.read.encode!('ISO-8859-1', 'UTF-8', :invalid => :replace, :undef => :replace, :replace => "")
				@stderr = e.read
				@stderr == "" ? parse : error
			end
		end

		def parse
			json_objects = []
			flows.each do |a|
				json_objects << JSON.parse(a)
				# JSONPath doesn't support symbolized names
				# json_objects << JSON.parse(a, :symbolize_names => true)
			end
			json_objects
		end

		def error
			puts "*"*60, "******* Error returned from readFromFlow python script:", "*"*60, @stderr, "*"*60
			exit 2
		end

		def flows
			@stdout.scan(/START <libmproxy.flow.Flow instance at [^{]+(.*?)\nEND <libmproxy.flow.Flow instance at /m).map { |e| e[0] }
		end
	
		alias_method :get_flows_from_file, :read_from_flow_dump
		public :get_flows_from_file
end