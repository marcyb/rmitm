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

require 'mitmdump'
require 'mitmdump_reader'
require 'mitm_flow_array'

def load_proxies(glob)
  Dir.glob(glob).each { |f| load f }
end

def proxy(name)
  $proxies[name.to_sym] or
    raise "Cannot find proxy '#{name}'"
end

def mitmdump(name, &block)
  $proxies ||= {}
  $proxies[name.to_sym] = Mitmdump.new(name, &block)
end
