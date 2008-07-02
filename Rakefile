require 'osx/cocoa' # dummy
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'erb'
require 'pathname'

def e_sh(str)
	str.to_s.gsub(/(?=[^a-zA-Z0-9_.\/\-\x7F-\xFF\n])/, '\\').gsub(/\n/, "'\n'").sub(/^$/, "''")
end

# Application own Settings
APPNAME   = "Ruby Class Browser"
TARGET    = "#{APPNAME}.app"
VERSION   = "#{`git log -1`[/commit ([A-z0-9]{10})/, 1]}"
RESOURCES = ["*.rb", "*.lproj", "Credits.*", "*.icns", "*.erb", "ri_outputter"]
PKGINC    = [e_sh(TARGET), 'README', 'html', 'client']
LOCALENIB = [] #['Japanese.lproj/Main.nib']
PUBLISH   = 'yourname@yourhost:path'

BUNDLEID  = "net.hardstylesensation.#{APPNAME}"

CLEAN.include ['**/.*.sw?', '*.dmg', TARGET, 'image', 'a.out']

# Tasks
task :default => [:test]

task :version do
  puts VERSION
end

desc 'Create Application Budle and Run it.'
task :test => [TARGET] do
	sh %{open '#{TARGET}'}
end

desc 'Create .dmg file for Publish'
task :package => [:clean, 'pkg', TARGET] do
	name = e_sh "#{APPNAME}.#{VERSION}"
	sh %{
	mkdir image
	cp -r #{PKGINC.join(' ')} image
	ln -s html/index.html image/index.html
	}
	puts 'Creating Image...'
	sh %{
	hdiutil create -volname #{name} -srcfolder image #{name}.dmg
	rm -rf image
	mv #{name}.dmg pkg
	}
end

desc 'Publish .dmg file to specific server.'
task :publish => [:package] do
	sh %{
	git log > CHANGES
	}
	_, host, path = */^([^\s]+):(.+)$/.match(PUBLISH)
	path = Pathname.new path
	puts "Publish: Host: %s, Path: %s" % [host, path]
	sh %{
	scp pkg/IIrcv.#{VERSION}.dmg #{PUBLISH}/pkg
	scp CHANGES #{PUBLISH}/pkg
	scp -r html/* #{PUBLISH}
	}
end

desc 'Make Localized nib from English.lproj and Lang.lproj/nib.strings'
rule(/.nib$/ => [proc {|tn| File.dirname(tn) + '/nib.strings' }]) do |t|
	p t.name
	lproj = File.dirname(t.name)
	target = File.basename(t.name)
	sh %{
	rm -rf #{t.name}
	nibtool -d #{lproj}/nib.strings -w #{t.name} English.lproj/#{target}
	}
end

# File tasks
desc 'Make executable Application Bundle'
file TARGET => [:clean, APPNAME] + LOCALENIB do
	sh %{
	mkdir -p "#{APPNAME}.app/Contents/MacOS"
	mkdir    "#{APPNAME}.app/Contents/Resources"
	cp -rp #{RESOURCES.join(' ')} "#{APPNAME}.app/Contents/Resources"
	cp '#{APPNAME}' "#{APPNAME}.app/Contents/MacOS"
	echo -n "APPL????" > "#{APPNAME}.app/Contents/PkgInfo"
	echo -n #{VERSION} > "#{APPNAME}.app/Contents/Resources/VERSION"
	}
	File.open("#{APPNAME}.app/Contents/Info.plist", "w") do |f|
		f.puts ERB.new(File.read("Info.plist.erb")).result
	end
end

file APPNAME => ['main.m'] do
	# Universal Binary
	sh %{gcc -arch ppc -arch i386 -Wall -lobjc -framework RubyCocoa main.m -o '#{APPNAME}'}
end

directory 'pkg'

