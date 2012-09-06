# -*- encoding: utf-8 -*-
require File.expand_path('../lib/qnd-cache/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Scott T Weaver"]
  gem.email         = ["scott.t.weaver@gmail.com"]
  gem.description   = %q{A simple caching system that supports multiple cache stores and disk spooling}
  gem.summary       = %q{A simple caching system that supports multiple cache stores and disk spooling}
  gem.homepage      = "https://github.com/scottweaver/qnd-cache"


  gem.add_development_dependency('rspec')
  gem.add_development_dependency('guard-rspec')
  gem.add_development_dependency('rb-inotify')
  gem.add_development_dependency('libnotify')
  gem.add_development_dependency('simplecov')
  
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "qnd-cache"
  gem.require_paths = ["lib"]
  gem.version       = Ruby::QuickAndDirtyCache::VERSION
end
