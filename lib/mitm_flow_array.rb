require_relative './mitmdump_reader'
require 'jsonpath'

class MitmFlowArray

	attr_reader :flows

	def initialize(file)
		@flows = MitmdumpReader.new(file).get_flows_from_file
	end

	def get_values(arr, jpath)
		arr.map { |f| JsonPath.new(jpath).on(f) }
	end

	def filter(conditions)
		result = @flows
		conditions.each do |jpath, re|
			result = result.select { |flow| JsonPath.new(jpath).first(flow).encode!('ISO-8859-1', 'UTF-8', :invalid => :replace, :undef => :replace, :replace => "") =~ re }
		end
		result
	end

end