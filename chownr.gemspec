
# -*- encoding: utf-8 -*-
$:.push('lib')
require "chownr/version"

Gem::Specification.new do |s|
  s.name     = "chownr"
  s.version  = Chownr::VERSION.dup
  s.date     = "2012-06-08"
  s.summary  = "TODO: Summary of project"
  s.email    = "todo@project.com"
  s.homepage = "http://todo.project.com/"
  s.authors  = ['Markus Strauss']
  
  s.description = <<-EOF
TODO: Long description 
EOF
  
  dependencies = [
    # Examples:
    # [:runtime,     "rack",  "~> 1.1"],
    # [:development, "rspec", "~> 2.1"],
  ]
  
  s.files         = Dir['**/*']
  s.test_files    = Dir['test/**/*'] + Dir['spec/**/*']
  s.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  
  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.8.11"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
  
  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
end
