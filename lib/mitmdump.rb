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

require 'fileutils'

class Mitmdump

	attr_reader :scripts, :params

	def initialize(name, &block)
		@name = name.to_sym
		@port = 8080
		@output = 'dumps/mitm.dump'
		@scripts = []
		@params = {}

		instance_eval &block
	end
### DSL
	def inherit(name)
		intersect = @params.keys & proxy(name.to_sym).params.keys
		intersect.empty? or
			raise "Duplicate parameters #{intersect} when inheriting proxy '#{name.to_sym}'"
		@scripts = @scripts | proxy(name.to_sym).scripts
		@params.merge! proxy(name.to_sym).params
	end

	def port(port)
		@port = port
	end

	def output(filename)
		@output = filename
	end

	def blacklist(path)
		script "#{script_path}blacklist.py", '-p' => path
	end

	def map_local(path, args={})
		unless args[:file].nil?
			script "#{script_path}map_local.py", '-p' => path, '-f' => args[:file]
		else
			raise ArgumentError, 'No file name provided for maplocal'
		end
	end

	def replace(path, args={})
		unless args[:swap].nil? | args[:with].nil?
			script "#{script_path}replace.py", '-p' => path, '-x' => args[:swap], '-r' => args[:with]
		else
			raise ArgumentError, "Expecting arguments ':swap' and ':with' for replace"
		end
	end

	def strip_encoding
		script "#{script_path}strip_encoding.py"
	end

	def script(file, args={})
		args.each do |k,v|
			unless (key = v[/%[a-zA-Z_]+/]).nil?
			 	@params.has_key?(key) or
			 		raise "Parameter '#{key}' referenced in proxy '#{@name}' but not declared"
			end
		end
		@scripts << [file, args]
	end

	def param(name)
		!@params.has_key?("%#{name.to_s}") and @params["%#{name.to_s}"] = '' or
			raise "Parameter name '#{name}' already declared"
	end	
### END DSL
	def start(args={})
		check_params(args)
		if port_available?
			manage_dumpfile
			@pid = Process.spawn command
			Process.detach @pid
			connection_successful? or
				raise "Failed to start mitmdump after 10 seconds\nCOMMAND LINE: <#{command}>"
		else
			raise "Cannot start mitmdump on port #{@port} - port unavailable"
		end
	end

	def stop
		pid = `ps --ppid #{@pid} -o pid h`
		system("kill #{pid}")
	end

	def dumpfile
		@output
	end

	private

		def port_available?
			# `nc -z 127.0.0.1 #{@port} >& /dev/null`
			system("nc -z 127.0.0.1 #{@port}")
			!$?.success?
		end

		def command
			cmd = "mitmdump -q -p #{@port} -w #{@output}"
			@scripts.each do | name, opts |
				cmd << " -s \"#{name}"
				opts.each { |k,v| cmd << " '#{k}' '#{interpolate(v)}'" } if opts
				cmd << "\""
			end
			cmd
		end

		def connection_successful?(timeout=10)
			timeout.times { port_available? and sleep 1 or return true }
			false
		end

		def manage_dumpfile
			FileUtils.rm_f @output if File.exists?(@output)
			d = File.dirname(@output)
			FileUtils.mkpath(d) unless File.directory?(d)
		end

		def script_path
			"#{File.expand_path('../../bin/scripts', __FILE__)}/"
		end

		def check_params(args={})
			@params.keys.each do |k|
				@params[k] = args[k[1..-1]] if args.has_key? k[1..-1] or 
					raise "Parameter '#{k}' not specified"
			end
		end

		def interpolate(str)
			str.gsub(/%[a-zA-Z_]+/, @params)
		end
end