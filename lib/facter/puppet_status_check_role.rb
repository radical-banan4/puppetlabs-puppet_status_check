Facter.add(:puppet_status_check_role) do
  confine { PuppetStatusCheck.enabled? }
  setcode do
    require_relative '../shared/puppet_status_check'

    begin
      PuppetStatusCheck.config('role')
    rescue StandardError => e
      Facter.debug("Could not resolve 'puppet_status_check_role' fact: #{e.message}")
      'unknown'
    end
  end
end
