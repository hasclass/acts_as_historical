require 'rake'
require 'rake/clean'

require 'rake/testtask'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'acts_as_historical/version'

CLOBBER.include %w( pkg *.gem documentation coverage measurements )


# === Helpers ================================================================

require 'date'

def replace_header(head, header_name, value)
  head.sub!(/(\.#{header_name}\s*= ').*'/) { "#{$1}#{value}'" }
end

# === Tasks ==================================================================

# --- Build ------------------------------------------------------------------

desc 'Builds the gem'
task :build => [:gemspec] do
  sh "mkdir -p pkg"
  sh "gem build acts_as_historical.gemspec"
  sh "mv acts_as_historical-#{ActsAsHistorical::VERSION}.gem pkg"
end

desc 'Create a fresh gemspec'
task :gemspec => :validate do
  gemspec_file = File.expand_path('../acts_as_historical.gemspec', __FILE__)

  # Read spec file and split out the manifest section.
  spec = File.read(gemspec_file)
  head, manifest, tail = spec.split("  # = MANIFEST =\n")

  # Replace version and date.
  replace_header head, :version, ActsAsHistorical::VERSION
  replace_header head, :date,    Date.today.to_s

  # Determine file list from git ls-files.
  files = `git ls-files`.
    split("\n").
    sort.
    reject { |file| file =~ /^\./ }.
    reject { |file| file =~ /^(rdoc|pkg|tasks|test)/ }

  # Format list for the gemspec.
  files = files.map { |file| "    #{file}" }.join("\n")

  # Piece file back together and write.
  manifest = "  s.files = %w[\n#{files}\n  ]\n"
  spec = [head, manifest, tail].join("  # = MANIFEST =\n")
  File.open(gemspec_file, 'w') { |io| io.write(spec) }

  puts "Updated #{gemspec_file}"
end

task :validate do
  unless Dir['lib/*'] - %w(lib/acts_as_historical.rb lib/acts_as_historical)
    puts 'The lib/ directory should only contain a acts_as_historical.rb ' \
         'file, and an acts_as_historical/ directory'
    exit!
  end

  unless Dir['VERSION*'].empty?
    puts 'A VERSION file at root level violates Gem best practices'
    exit!
  end
end

# --- Tests ------------------------------------------------------------------

Rake::TestTask.new(:test) do |test|
  test.libs << 'test' << 'rails'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern   = 'test/*_test.rb'
    test.verbose   = true

    test.rcov_opts = '--rails --exclude osx\/objc,gems\/,spec\/,features\/ ' \
                     '--aggregate coverage.data'
  end
rescue LoadError
  task :rcov do
    abort 'RCov is not available. In order to run rcov, you must: gem ' \
          'install spicycode-rcov'
  end
end

# --- Documentation ----------------------------------------------------------

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "acts_as_historical #{ActsAsHistorical::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :test
