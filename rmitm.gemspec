# -*- encoding: utf-8 -*-
# $:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name          = 'rmitm'
  s.version       = '0.0.1'
  s.license       = 'GPL-3.0'
  s.date          = '2014-06-13'
  s.summary       = "rmitm provides useful ruby classes and python scripts for mitmdump"
  s.description   = <<-EOF
  rmitm provides useful ruby classes and python scripts for using mitmdump
  for automated testing.
EOF
  s.authors       = ["Marc Bleeze"]
  s.email         = 'marcbleeze@gmail.com'
  s.files         = Dir.glob("{bin,lib}/**/*")
  s.require_paths = ["lib"]

  s.add_runtime_dependency "sys-proctable"
  s.add_runtime_dependency "jsonpath"
  s.add_runtime_dependency "json"

end