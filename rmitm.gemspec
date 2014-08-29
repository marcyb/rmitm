
Gem::Specification.new do |s|
  s.name          = 'rmitm'
  s.version       = '0.0.5'
  s.license       = 'GPL-3.0'
  s.date          = '2014-07-01'
  s.summary       = "rmitm provides a DSL and useful ruby classes and python scripts for mitmdump"
  s.description   = <<-EOF
  rmitm provides a DSL and useful ruby classes and python scripts for using mitmdump
  for automated testing.
EOF
  s.authors       = ["Marc Bleeze"]
  s.email         = 'marcbleeze@gmail.com'
  s.files         = Dir.glob("{bin,lib}/**/*")
  s.require_paths = ["lib"]
  s.homepage = 'https://github.com/marcyb/rmitm'

  s.add_runtime_dependency "jsonpath", '~> 0.5', '>= 0.5.6'
  s.add_runtime_dependency "json", '~> 1.8', '>= 1.8.1'

end