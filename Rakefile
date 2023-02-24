# Copyright 2007-present Greg Hurrell. All rights reserved.
# Licensed under the terms of the BSD 2-clause license.

require 'rake'
require 'rubygems'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'
require File.expand_path('lib/walrat/version', File.dirname(__FILE__))

desc 'Run specs with coverage'
Spec::Rake::SpecTask.new('coverage') do |t|
  t.spec_files  = FileList['spec/**/*_spec.rb']
  t.rcov        = true
  t.rcov_opts = ['--exclude', "spec"]
end

desc 'Run specs'
task :spec do
  sh 'bin/spec spec'
end

desc 'Verify that test coverage is above minimum threshold'
RCov::VerifyTask.new(:verify => :spec) do |t|
  t.threshold   = 99.2 # never adjust expected coverage down, only up
  t.index_html  = 'coverage/index.html'
end

desc 'Generate specdocs for inclusions in RDoc'
Spec::Rake::SpecTask.new('specdoc') do |t|
  t.spec_files  = FileList['spec/**/*_spec.rb']
  t.spec_opts   = ['--format', 'rdoc']
  t.out         = 'specdoc.rd'
end

desc 'Build the YARD HTML files'
task :yard do
  sh 'bin/yardoc -o html --title Walrat'
end

desc 'Upload YARD HTML'
task :upload_yard => :yard do
  require 'yaml'
  config = YAML.load_file('.config.yml')
  raise ':yardoc_host not configured' unless config.has_key?(:yardoc_host)
  raise ':yardoc_path not configured' unless config.has_key?(:yardoc_path)
  sh "scp -r html/* #{config[:yardoc_host]}:#{config[:yardoc_path]}"
end

BUILT_GEM_DEPENDENCIES = Dir[
  'walrat.gemspec',
  'lib/**/*.rb'
]

BUILT_GEM = "walrat-#{Walrat::VERSION}.gem"
file BUILT_GEM => BUILT_GEM_DEPENDENCIES do
  sh 'gem build walrat.gemspec'
end

desc 'Build gem ("gem build")'
task :build => BUILT_GEM

desc 'Publish gem ("gem push")'
task :push => :build do
  sh "gem push #{BUILT_GEM}"
end
