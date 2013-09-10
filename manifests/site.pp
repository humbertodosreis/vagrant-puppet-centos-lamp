stage { setup: before => Stage[main] }

Exec {
    path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ]
}

File {
	mode => '0644'
}

class proxy {
	$proxy_username = 't31291157816'
	$proxy_domain = 'DASA'
	$proxy_password = '7187A15D1382A8D03C856613F5A554FE'
	$proxy_url = 'proxy-sp.dasa.net'
	$proxy_port = '3128'
	$proxy_no_proxy = 'localhost, 127.0.0.*, 10.*, 192.168.*, *.dasa.com.br, *.dasa.net, 172.*'
	$proxy_listen = '3128'	
	$proxys = ["proxy=http://${proxy_url}:${proxy_port}","proxy=ftp://${proxy_url}:${proxy_port}","proxy=https://${proxy_url}:${proxy_port}"]	
	$config_proxys = ['yum.conf', 'profile', 'wgetrc']

	define applyproxy() {
		file {$name:
			owner   => "root",
			group   => "root",
			mode => '0644',
			ensure => present,
			replace => true,
			path => "/etc/${name}",
			source => "/vagrant/files/${name}"
		}

		notify {"Aplicando configuração de proxy em ${name}":}
	}
	
	exec {'install-cntlm':
		command => 'rpm -Uvh /vagrant/files/cntlm-*.rpm',
		creates => "/etc/cntlm.conf"
	}
	
	file { '/etc/cntlm.conf':
		mode => '0644',
		owner   => "root",
		group   => "root",
		ensure => present,
		replace => true,
		require => Exec['install-cntlm'],
		notify => Service['cntlmd'],
		content => template("/vagrant/templates/cntlm/cntlm.conf.erb")
	}
	
	service { 'cntlmd':
		ensure => 'running'
	}
	
	applyproxy {$config_proxys:}	
}

class install {
	
	
	define yumgroup($ensure = "present", $optional = false) {
	   case $ensure {
		  present,installed: {
			 $pkg_types_arg = $optional ? {
				true => "--setopt=group_package_types=optional,default,mandatory",
				default => ""
			 }
			 exec { "Installing $name yum group":
				command => "yum -y groupinstall $pkg_types_arg $name",
				unless => "yum -y groupinstall $pkg_types_arg $name --downloadonly",
				timeout => 600,
			 }
		  }
	   }
	}
	
	exec { 'yum-update':
		command => '/usr/bin/yum -y update',
		require => Class["epel"],
		timeout => 60,
		tries   => 3
	}
	
	class { 'epel': }
	
	yumgroup { ['"Development tools"', '"Development Libraries"']:
		require => Exec['yum-update']
	}
	
	package {['vim-enhanced', 'vim-common', 'vim-minimal', 'telnet','zip','unzip','git','nodejs','npm','upstart', 'zlib-devel', 'lynx']:
		ensure => latest,
		require => Exec['yum-update']
	}

}

class {'proxy': 
	# Força a execução do cntlm antes de todos as outras tarefas
	stage => setup
}

include install



