class Mitmdump
	
	def blacklist(path)
		add_script_to_startup('blacklist.py',
			{
				'-p' => path
			}
		)
	end

	def map_local(path, file)
		add_script_to_startup('map_local.py', 
			{ 
	      '-p' => path,
				'-f' => file
			}
		)	
	end

	def replace(path, regex, repl)
		add_script_to_startup('replace.py',
			{
				'-p' => path,
				'-x' => regex,
				'-r' => repl
			}
		)
	end

	def strip_encoding
		add_script_to_startup('strip_encoding.py')
	end

end