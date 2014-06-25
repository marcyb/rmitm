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