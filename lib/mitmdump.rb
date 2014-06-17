require 'sys/proctable'
require 'fileutils'
include Sys

class Mitmdump

	def initialize(paths=[])
		@args = defaults
		@path_arr = [File.expand_path('../../bin/scripts', __FILE__)] #bundled scripts
		set_script_lookup_paths(paths)
	end

	def add_script_to_startup(script, args = {})
		# # only makes sense to add a script before proxy is started
		return nil if running?
		unless (cmd = get_script_path(script)).nil?
			args.each do |o, v|
				cmd << " " << o << " " << "'" << v << "'"
			end
			@args['-s'] << "\"#{cmd}\""
		end
	end

	def reset_scripts
		@args['-s'] = defaults['-s']
	end

	def dumpfile
		@args['-w']
	end

	def scripts
		@args['-s']
	end

	def port
		@args['-p'] || '8080'
	end

	def script_paths
		@path_arr[1..-1]
	end

	def start(options={})
		merge(options)
		stop if running?
		p command if $DEBUG
		pid = Process.spawn command 
		Process.detach pid
		wait_for_connection(true)
		reset_scripts
	end

	alias_method :restart, :start

	def stop
		ProcTable.ps { |p| Process.kill("SIGKILL", p.pid) if p.cmdline =~ /mitmdump/ }
		wait_for_connection(false)
	end

	private

		def set_script_lookup_paths(path_array)
			@path_arr << path_array if path_array
			@path_arr.flatten!
			@path_arr.map! { |p| File.expand_path(p) }.uniq!		
		end

		def defaults
			{
				'-q' => nil,
				'-w' => "dumps/selenium.dump",
				'-s' => [] 
			}
		end

		def get_script_path(file)
			# careful of naming conflicts - the first one found will be used
			path = @path_arr.find { |p| File.exists?("#{p}/#{file}") } and "#{path}/#{file}"
		end

		def merge(options = {})
			maintain_dumps(options['-w'])
			@args = @args.merge(options)
		end

		def maintain_dumps(file)
			if File.exists?(dumpfile)
				FileUtils.rm_f dumpfile
				d = File.dirname(dumpfile)
				FileUtils.remove_dir(d) if Dir.entries(d).size <= 2
			end
			d = File.dirname(file || defaults['-w'])
			FileUtils.mkpath(d) unless File.directory?(d)
		end

		def command
			cmd = "mitmdump"
			@args.each do |o, v|
				unless o == '-s'
					cmd << " #{o}#{" #{v}" if v}"
				else
					v.each do |s|
						cmd << " -s" << " " << s
					end
				end
			end
			cmd
		end

		def wait_for_connection(success)
			result = success ? 1 : 0
			pid = Process.spawn "MITM=#{result}; while [ $MITM -eq #{result} ]; do sleep 1; nc -z 127.0.0.1 #{port} >& /dev/null; MITM=$?; done; exit"
			Process.wait pid
		end

		def running?
			ProcTable.ps.find { |p| p.cmdline =~ /mitmdump/ }
		end
end