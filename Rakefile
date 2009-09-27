require 'rubygems'
require 'spec/rake/spectask'

NAME = 'rack-session-stack'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = NAME
    s.platform = Gem::Platform::RUBY
    s.summary = NAME
    s.description = NAME
    s.author = "Jun Kikuchi"
    s.email = "kikuchi@bonnou.com"
    s.homepage = "http://github.com/JunKikuchi/rack-session-stack"
    s.files = %w(COPYING CHANGELOG README.rdoc Rakefile VERSION) + Dir.glob("{bin,doc,spec,lib}/**/*")
    s.require_path = "lib"
    s.has_rdoc = true
    s.add_dependency('uuidtools','>= 2.0.0')
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

Spec::Rake::SpecTask.new do |t|
  #t.spec_opts = ['-c --format specdoc']
  t.spec_opts = ['-c']
  t.spec_files = FileList['spec/**/*_spec.rb']
end
