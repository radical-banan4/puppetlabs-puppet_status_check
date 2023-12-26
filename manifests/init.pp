# @summary puppet_status_check fact and failed indicators
#
# When this class is included and enabled, any of the indicators in the
# puppet_status_check fact that are false will add a notify resource to the
# catalog.
# Individual indicators can be disabled by adding the ID to the
# indicator_exclusions parameter.
#
# @example
#   include 'puppet_status_check':
#
# @param enabled
#   Enable checks
# @param role
#   Role node performs
# @param indicate
#   Enable notify resources for failed checks
# @param indicator_exclusions
#   List of disabled indicators, place any indicator ids you do not wish to
#   report on in this list
# @param checks
#   Hash containing a description for each check
# @param postgresql_service
#   Name of postgresql service unit
# @param pg_config_path
#   Path to postgresql pg_config binary
class puppet_status_check (
  Hash $checks,
  String $postgresql_service = 'postgresql',
  String $pg_config_path = 'pg_config',
  Puppet_status_check::Role $role = 'agent',
  Boolean $enabled = true,
  Boolean $indicate = true,
  Array[String[1]] $indicator_exclusions = ['AS002', 'AS003', 'S0006'],
) {
  $_base_path = $facts['os']['family'] ? {
    'windows' => "${facts['common_appdata']}/PuppetLabs",
    default   => '/opt/puppetlabs'
  }

  $_file_ensure = $enabled ? {
    true     => 'file',
    default => 'absent',
  }

  file { "${_base_path}/puppet/cache/state/status_check.json":
    ensure  => $_file_ensure,
    mode    => '0664',
    content => @("EOD")
      {
        "role": "${role}",
        "pg_config": "${pg_config_path}",
        "postgresql_service": "${postgresql_service}"
      }
      | EOD
    ,
  }

  if $indicate {
    $negatives = getvar('facts.puppet_status_check', []).filter | $k, $v | {
      $v == false and ! ($k in $indicator_exclusions)
    }

    $negatives.each |$indicator, $_v| {
      $msg = $checks[$indicator]
      notify { "puppet_status_check ${indicator}":
        message => "${indicator} is at fault, ${msg}. Refer to documentation for required action.",
      }
    }
  }
}
