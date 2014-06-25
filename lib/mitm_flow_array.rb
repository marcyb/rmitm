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

require_relative './mitmdump_reader'
require 'jsonpath'

class MitmFlowArray < Array

	def self.from_file(filename)
		MitmFlowArray.new(MitmdumpReader.new(filename).get_flows_from_file)
	end

	def values_by_jpath(jpath, first=true)
		self.map { |f| first ? JsonPath.new(jpath).first(f) : JsonPath.new(jpath).on(f) }
	end

	def filter(conditions)
		result = self
		conditions.each do |jpath, re|
			result = result.select { |flow| JsonPath.new(jpath).first(flow).encode!('ISO-8859-1', 'UTF-8', :invalid => :replace, :undef => :replace, :replace => "") =~ re }
		end
		MitmFlowArray.new(result)
	end

end