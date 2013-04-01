# -*- encoding: utf-8 -*-
#!/usr/bin/ruby

# for applescript ui

require "fileutils"
require "date"

FILE_NAME = "/etc/apache2/extra/httpd-vhosts.conf"

option = ARGV[0]
port_no = ARGV[1]
doc_root = ARGV[2]

#
if option == "list"
  #fileのオープン
  f = File.open( FILE_NAME, "r")
  begin
    vhosts = f.read
  ensure
    f.close
  end
  res = []
  vhosts.scan(/<VirtualHost \*:(\d+)>.+?DocumentRoot "(.+?)"\n/m) do |port, dir|
    #puts "#{port} #{dir}"
	  res.push( { :port => port, :dir => dir } )
  end
  res.sort! do |a,b|
	  a[:port].to_i <=> b[:port].to_i
  end
  res.each do |vhost|
	  puts "#{vhost[:port]} \t #{vhost[:dir]}"
  end
  exit
elsif option == "ports"
	f = File.open( FILE_NAME, "r")
	begin
		vhosts = f.read
	ensure
		f.close
	end
	res = []
	vhosts.scan(/<VirtualHost \*:(\d+)>.+?DocumentRoot "(.+?)"\n/m) do |port, dir|
		#puts "#{port} #{dir}"
		res.push "#{port}"
	end
	res.sort! do |a,b|
		a.to_i <=> b.to_i
	end
	puts res.join(",")
	exit
end

#バックアップをとる
FileUtils.copy( FILE_NAME, "#{FILE_NAME}.#{( DateTime.now() ).strftime("%Y%m%d%H%M%S")}" )

#fileのオープン
f = File.open( FILE_NAME, "r")
begin
  vhosts = f.read
ensure
  f.close
end

#puts "ドキュメントルートは？"
#doc_root = STDIN.gets.to_s.chomp
#until File.exist?(doc_root)
#  puts "そんなのないです。ドキュメントルートは？"
#  doc_root = STDIN.gets.to_s.chomp
#end

#puts "ポート番号は?"
#port_no = STDIN.gets.to_s.chomp

if vhosts.match(/<VirtualHost \*:#{port_no}>/m)
  #puts "ありますね。変更します。"

  #document root
  vhosts.match(/<VirtualHost \*:#{port_no}>.+?DocumentRoot "(.+?)"\n/m)
	#puts $1
  vhosts.sub!($1, "#{doc_root}")

  #vhosts.sub(/<VirtualHost \*:#{port_no}>(.+DocumentRoot)? (".+").+?ServerName/m, "#{doc_root}")
  #puts vhosts
else
  #puts "ないです。作ります。"
  #Listen
  if vhosts.match(/(Listen \d+\n)+(\n)/m)
		vhosts.sub!($1, "#{$1}Listen #{port_no}\n")
	else
		vhosts = "#{$1}Listen #{port_no}\n" + vhosts
	end

  #<VirtualHost
  vhosts += <<"DOC"


<VirtualHost *:#{port_no}>
    ServerAdmin webmaster@localhost
    DocumentRoot "#{doc_root}"
    ServerName #{port_no}
    ErrorLog "/private/var/log/apache2/#{port_no}-error_log"
    CustomLog "/private/var/log/apache2/#{port_no}-access_log" common
</VirtualHost>
DOC

end

#puts vhosts

#f = File.open( FILE_NAME, "r+")
#begin
#  f.flock(File::LOCK_EX) do |file|
#    file.write vhosts
#    file.flush
#  end
#ensure
#  f.close
#end

File.open( FILE_NAME, "w" ) do |f|
  f.write vhosts
end

puts "完了しました。"
