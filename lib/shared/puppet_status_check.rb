require 'puppet'
require 'json'
require 'net/http'
require 'openssl'

# PuppetStatusCheck - Shared code for puppet_status_check facts
module PuppetStatusCheck
  class << self
    attr_accessor :facter_timeout
  end

  self.facter_timeout ||= 2

  module_function

  # Gets the resource object by name
  # @param resource [String] The resource type to get
  # @param name [String] The name of the resource
  # @return [Puppet::Resource] The instance of the resource or nil
  def get_resource(resource, name)
    name += '.service' if (resource == 'service') && !name.include?('.')
    Puppet::Indirector::Indirection.instance(:resource).find("#{resource}/#{name}")
  rescue ScriptError, StandardError => e
    Facter.debug("Error when finding resource #{resource}: #{e.message}")
    Facter.debug(e.backtrace)
    nil
  end

  # Check if the service is running
  # @param name [String] The name of the service
  # @param service [Puppet::Resource] An optional service resource to use
  # @return [Boolean] True if the service is running
  def service_running(name, service = nil)
    service ||= get_resource('service', name)
    return false if service.nil?

    service[:ensure] == :running
  end

  # Check if the service is enabled
  # @param name [String] The name of the service
  # @param service [Puppet::Resource] An optional service resource to use
  # @return [Boolean] True if the service is enabled
  def service_enabled(name, service = nil)
    service ||= get_resource('service', name)
    return false if service.nil?

    service[:enable].to_s.casecmp('true').zero?
  end

  # Check if the service is running and enabled
  # @param name [String] The name of the service
  # @param service [Puppet::Resource] An optional service resource to use
  # @return [Boolean] True if the service is running and enabled
  def service_running_enabled(name, service = nil)
    service ||= get_resource('service', name)
    return false if service.nil?

    service_running(name, service) and service_enabled(name, service)
  end

  # Return the name of the postgresql service for the current OS
  # @return [String] The name of the postgresql service
  def postgres_service_name
    config('postgresql_service') % { 'pg_major_version': pg_major_version }
  end

  # Checks if passed service file exists in correct directory for the OS
  # @return [Boolean] true if file exists
  # @param configfile [String] The name of the pe service to be tested
  def service_file_exist?(configfile)
    configdir = if Facter.value(:os)['family'].eql?('RedHat') || Facter.value(:os)['family'].eql?('Suse')
                  '/etc/sysconfig'
                else
                  '/etc/default'
                end
    File.exist?("#{configdir}/#{configfile}")
  end

  # Module method to make a GET request to an api specified by path and port params
  # @return [Hash] Response body of the API call
  # @param path [String] The API path to query.  Should include a '/' prefix and query parameters
  # @param port [Integer] The port to use
  # @param host [String] The FQDN to use in making the connection.  Defaults to the Puppet certname
  def http_get(path, port, host = Puppet[:certname])
    # Use an instance variable to only create an SSLContext once
    @ssl_context ||= Puppet::SSL::SSLContext.new(
      cacerts: Puppet[:localcacert],
      private_key: OpenSSL::PKey::RSA.new(File.read(Puppet[:hostprivkey])),
      client_cert: OpenSSL::X509::Certificate.new(File.open(Puppet[:hostcert])),
    )

    client = Net::HTTP.new(host, port)
    # The main reason to use this approach is to set open and read timeouts to a small value
    # Puppet's HTTP client does not allow access to these
    client.open_timeout = 2
    client.read_timeout = 2
    client.use_ssl = true
    client.verify_mode = OpenSSL::SSL::VERIFY_PEER
    client.cert = @ssl_context.client_cert
    client.key = @ssl_context.private_key
    client.ca_file = @ssl_context.cacerts

    response = client.request_get(Puppet::Util.uri_encode(path))
    if response.is_a? Net::HTTPSuccess
      JSON.parse(response.body)
    else
      false
    end
  rescue StandardError => e
    Facter.debug("Error in fact 'puppet_status_check' when querying #{path}: #{e.message}")
    Facter.debug(e.backtrace)
    false
  end

  def pg_config(option)
    @pg_options ||= {}
    @pg_options[option] ||= Facter::Core::Execution.execute("#{config('pg_config')} --#{option}", { timeout: facter_timeout, on_fail: nil })
  end

  # Get the maximum defined and current connections to Postgres
  def psql_return_result(sql, psql_options = '')
    command = %(su postgres --shell /bin/bash --command "cd /tmp && #{pg_config('bindir')}/psql #{psql_options} --command \\"#{sql}\\"")
    Facter::Core::Execution.execute(command, { timeout: facter_timeout, on_fail: nil })
  end

  def postgresql_version
    @pg_version ||= pg_config('version').match(%r{PostgreSQL (\d+)\.(\d+) })
  end

  def pg_major_version
    postgresql_version[1]
  end

  def pg_minor_version
    postgresql_version[2]
  end

  def max_connections
    sql = %(
    SELECT current_setting('max_connections');
  )
    psql_options = '-qtAX'
    psql_return_result(sql, psql_options)
  end

  def cur_connections
    sql = %(
    select count(*) used from pg_stat_activity;
  )
    psql_options = '-qtAX'
    psql_return_result(sql, psql_options)
  end

  def pg_data_dir
    sql = %(
    SHOW data_directory;
  )
    psql_options = '-qtAX'
    psql_return_result(sql, psql_options)
  end

  # Get the free disk percentage from a path
  # @param path [String] The path on the file system
  # @return [Integer] The percentage of free disk space on the mount
  def filesystem_free(path)
    require 'sys/filesystem'

    stat = Sys::Filesystem.stat(path)
    (stat.blocks_available.to_f / stat.blocks.to_f * 100).to_i
  rescue LoadError => e
    Facter.warn("Error in fact 'puppet_status_check': #{e.message}")
    Facter.debug(e.backtrace)
    0
  end

  def config(option)
    enabled_file = '/opt/puppetlabs/puppet/cache/state/status_check.json'
    if Facter.value('os')['name'] == 'windows'
      enabled_file = File.join(Facter.value('common_appdata'),
                               'PuppetLabs/puppet/cache/state/status_check.json')
    end

    @config ||= JSON.parse(File.read(enabled_file)) if File.exist?(enabled_file)
    @config[option]
  end

  def enabled?
    config('role').instance_of?(String)
  end
end
