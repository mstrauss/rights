require 'optparse'
require 'pathname'
require 'ostruct'
require 'open4'

basedir = Pathname( File.dirname(__FILE__) )
$:.unshift(basedir) unless $:.include?(basedir) || $:.include?(File.expand_path(basedir))

def require_all( dir )
  basedir = Pathname( File.dirname(__FILE__) )
  Dir[File.join(basedir, "#{dir}/*.rb")].each do |file|
    require Pathname(file).relative_path_from(basedir).to_s.chomp('.rb')
  end
end

require_all 'ext'
require_all 'rights'
