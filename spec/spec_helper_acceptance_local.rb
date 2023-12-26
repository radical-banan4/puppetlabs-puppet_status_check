# frozen_string_literal: true

require 'singleton'
require 'serverspec'
require 'puppetlabs_spec_helper/module_spec_helper'
include PuppetLitmus

RSpec.configure do |c|
  c.mock_with :rspec
  c.before :suite do
    # Download the plugins to ensure up-to-date facts
    PuppetLitmus::PuppetHelpers.run_shell('/opt/puppetlabs/bin/puppet plugin download')

    # Wait for the puppetserver to fully come online before running the tests
    timeout = <<-TIME
    timeout 300 bash -c 'while [[ "$(curl -s -k -o /dev/null -w ''%{http_code}'' https://127.0.0.1:8140/status/v1/simple)" != "200" ]]; do sleep 5; done' || false
    TIME
    PuppetLitmus::PuppetHelpers.run_shell(timeout)

    # Ensure there is no running agent process and default to a disabled agent
    PuppetLitmus::PuppetHelpers.run_shell('puppet resource service puppet ensure=stopped; puppet agent --disable; puppet resource service puppet ensure=running;')
  end
end
