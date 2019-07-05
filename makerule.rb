#!/usr/bin/env ruby

dns = ''; nodes = []
`kubectl get service -A`.split(/\n/).each {|l|
	ls = l.split(/\s+/)
	ls[1] =~ /^(NAME|kubernetes|rproxy4kube)/ and next
	ls[1] =~ /^kube-dns/ and dns = ls[3] and next
	ls[5] =~ /(\d+)\/TCP/ and nodes << {
		:SRC	=> l,
		:SVC	=> ls,
		:HOST	=> nil,
		:PORT	=> $1,
	}
}

nodes.each {|node|
	`dig -x #{node[:SVC][3]} @#{dns}`.split(/\n/).each {|l|
		l =~ /^\d.+PTR\s+(.+)/ and node[:HOST] = $1.split(/\./)
	}
}

apache_conf =<<CONF

ProxyPass /%s http://%s:%s/xxxxxx
ProxyPassReverse /%s http://%s:%s/xxxxxx
 
<Location /%s>
	RewriteEngine   On
	RewriteCond %%{HTTPS} !=on
	RewriteRule (.*) https://%%{HTTP_HOST}%%{REQUEST_URI}
 
	AuthType		Digest
	AuthName		"%s"
	AuthUserFile	/var/www/.digest_pw
	<RequireAny>
		Require		valid-user
	</RequireAny>
</Location>

# htdigest +c ../pv/dot.digest_pw "%s" user

CONF

puts('ProxyRequests Off')
nodes.each {|node|
	puts("\n# " + node[:SRC])
	puts(apache_conf % [
		node[:HOST][0],
		node[:HOST].join('.'),
		node[:PORT],
		node[:HOST][0],
		node[:HOST].join('.'),
		node[:PORT],
		node[:HOST][0],
		node[:HOST][0].capitalize,
		node[:HOST][0].capitalize,
	])
}
puts('# ./makerule.rb > ../pv/rproxy.conf')

__END__

