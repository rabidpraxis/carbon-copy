$:.push File.expand_path("../lib", __FILE__)  
require 'carbon-copy/version'

Gem::Specification.new do |gem|
  gem.authors = ["Kevin Webster"]
  gem.email   = ["me@kdoubleyou.com"]

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = "Al"
  gem.require_paths = ["lib"]
  gem.version       = CarbonCopy::VERSION
end
