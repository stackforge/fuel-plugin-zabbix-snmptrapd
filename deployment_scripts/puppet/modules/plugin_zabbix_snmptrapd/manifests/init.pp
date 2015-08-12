#
#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
class plugin_zabbix_snmptrapd {

  include plugin_zabbix_snmptrapd::params

  $service_name     = $plugin_zabbix_snmptrapd::params::service_name
  $package_name     = $plugin_zabbix_snmptrapd::params::package_name

  $plugin_settings  = hiera('zabbix_snmptrapd')

  $network_metadata = hiera('network_metadata')
  $server_ip        = $network_metadata['vips']['zabbix_vip_management']['ipaddr']
  $server_port      = '162'

  class { 'snmp':
    snmptrapdaddr       => ["udp:${server_ip}:${server_port}"],
    ro_community        => $plugin_settings['community'],
    service_ensure      => 'stopped',
    trap_service_ensure => 'running',
    trap_service_enable => true,
    trap_handlers       => ['default /usr/sbin/snmptthandler'],
  }

  firewall { '998 snmptrapd':
    proto     => 'udp',
    action    => 'accept',
    port      => $server_port,
  }

  file { "/etc/init.d/${service_name}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => "puppet:///modules/plugin_zabbix_snmptrapd/initscripts/${service_name}",
    require => Package[$package_name],
    notify  => Service[$service_name],
  }

  class { 'plugin_zabbix_snmptrapd::snmptt':
    require => Class['snmp'],
  }

  class { 'plugin_zabbix_snmptrapd::zabbix':
    require => Class['plugin_zabbix_snmptrapd::snmptt'],
  }

}
