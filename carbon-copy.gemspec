$:.push File.expand_path("../lib", __FILE__)  
require 'carbon-copy'

Gem::Specification.new do |gem|
  gem.authors = ["Kevin Webster"]
  gem.email   = ["me@kdoubleyou.com"]

  gem.description = "easily cache them REST calls"
  gem.summary     = "REST cache"
  gem.homepage    = 'https://github.com/rabidpraxis/carbon-copy'
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = "carbon-copy"
  gem.require_paths = ["lib"]
  gem.version       = CarbonCopy::VERSION
  gem.executables   = ['carbon-copy']
end
