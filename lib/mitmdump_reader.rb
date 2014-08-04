=begin
    RMITM - provides a Ruby interface to mitmdump
    Copyright (C) 2014  Marc Bleeze (marcbleeze<at>gmail<dot>com)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

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
				@stdout = o.read #.encode!('ISO-8859-1', 'UTF-8', :invalid => :replace, :undef => :replace, :replace => "")
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