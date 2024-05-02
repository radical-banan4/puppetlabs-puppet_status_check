# Puppet Status Check

- [Description](#description)
- [Setup](#setup)
  - [What this module affects](#what-this-module-affects)
  - [Setup requirements](#setup-requirements)
- [Usage](#usage)
  - [Enable infrastructure checks](#enable-infrastructure-checks)
  - [Disable](#disable)
- [Reporting Options](#reporting-options)
  - [Class declaration](#class-declaration)
  - [Using a Puppetdb Query to report status.](#using-a-puppetdb-query-to-report-status)
  - [Ad-hoc Report (Plans)](#ad-hoc-report-plans)
    - [Setup Requirements](#setup-requirements-1)
    - [Running the plans](#running-the-plans)
- [Reference](#reference)
  - [Facts](#facts)
    - [puppet_status_check_role](#puppet_status_check_role)
    - [puppet_status_check](#puppet_status_check)
- [How to report an issue or contribute to the module](#how-to-report-an-issue-or-contribute-to-the-module)

## Description

Puppet Status Check provides a way to alert the end-user when Puppet is not in an ideal state. It uses pre-set indicators and has a simplified output that directs the end-user to the next steps for resolution.

## Setup

### What this module affects

This module primarily provides status indicators the fact named `puppet_status_check`. Once nodes have been classified with the module, facts will be generated and the optional indicators can occur. By default, fact collection is set to only check the status of the Puppet agent. Puppet infrastructure checks require additional configuration.

### Setup requirements

Install the module, plug-in sync will be used to deliver the required facts for this module, to each agent node in the environment the module is installed in.

## Usage

Classify nodes with `puppet_status_check`. Notify resources will be added to a node on each Puppet run if indicator's are reporting as `false`. These can be viewed in the Puppet report for each node, or queried from Puppetdb.

### Enable infrastructure checks

The default fact population will not perform checks related to puppet infrastructure services such as the puppetserver, puppetdb, or postgresql. To enable the checks for Puppet servers, set the following parameter to those infrastructure node(s):

```
puppet_status_check::role: primary
```

### Disable

To completely disable the collection of `puppet_status_check` facts, uninstall the module or [classify the module](#class-declaration) with the `enabled` parameter:

```
puppet_status_check::enabled: false
```

## Reporting Options

### Class declaration

To enable fact collection and configure notifications, classify nodes with the `puppet_status_check` class. Examples using `site.pp`:

1. Check basic agent status:
   ```puppet
   node 'node.example.com' {
     include 'puppet_status_check'
   }
   ```
2. Check puppet server infrastructure status:
   ```puppet
   node 'node.example.com' {
     class { 'puppet_status_check':
       role => 'primary',
     }
   }
   ```
3. For maximum coverage, report on all default indicators. However, if you need to make exceptions for your environment, classify the array parameter `indicator_exclusions` with a list of all the indicators you do not want to report on.
   ```puppet
   class { 'puppet_status_check':
     indicator_exclusions => ['S0001','S0003','S0003','S0004'],
   }
   ```

### Using a Puppetdb query to report status.

As the module uses Puppet's existing fact behavior to gather the status data from each of the agents, it is possible to use PQL (puppet query language) to gather this information.

Consult with your local Puppet administrator to construct a query suited to your organizational needs. 
Please find some examples of using the [puppetdb_cli gem][1] to query the status check facts below:

1. To find the complete output from all nodes listed by certname (this could be a large query based on the number of agent nodes, further filtering is advised ):
   ```shell
   puppet query 'facts[certname,value] { name = "puppet_status_check" }'
   ```
2. To find the complete output from all nodes listed by certname with the `primary` role:
   ```shell
   puppet query 'facts[certname,value] { name = "puppet_status_check" and certname in facts[certname] { name = "puppet_status_check_role" and value = "primary" } }'
   ```
3. To find those nodes with a specific status check set to false:
   ```shell
   puppet query 'inventory[certname] { facts.puppet_status_check.S0001 = false }'
   ```

### Ad-hoc Report (Plans)

The plan `puppet_status_check::summary` summarizes the status of each of the checks on target nodes that have the `puppet_status_check` fact enabled. Sample output can be seen below:

**TBC**

#### Setup Requirements

[Hiera][2] is utilized to lookup test definitions, this requires placing a static hierarchy in your **environment level** [hiera.yaml][3].

```yaml
plan_hierarchy:
  - name: "Static data"
    path: "static.yaml"
    data_hash: yaml_data
```

_Refer to the [bolt hiera documentation][4] for further explanation._

#### Using Static Hiera data to populate indicator_exclusions when executing plans

Place the *plan_hierarchy* listed in the step above, in the environment layer.

Create a [static.yaml] file in the environment layer hiera data directory
```yaml
puppet_status_check::indicator_exclusions:                                             
  - '<TEST ID>'                                                                
``` 

Indicator ID's within array will be excluded when running the `puppet_status_check::summary` plan.

#### Running the plans

The `puppet_status_check::summary` plans can be run from the [Puppet Bolt][5]. More information on parameters of the plan can be viewed in [REFERENCE.md].

1. Example call from the command line to run `puppet_status_check::summary` against all infrastructure nodes:
   ```shell
   bolt plan run puppet_status_check::summary role=primary
   ```
2. Example call from the command line to run `puppet_status_check::summary` against all regular agent nodes:
   ```shell
   bolt plan run puppet_status_check:summary role=agent
   ```
3. Example call from the command line to run against a set of infrastructure nodes:
   ```shell
   bolt plan run puppet_status_check::summary targets=server-70aefa-0.region-a.domain.com,psql-70aefa-0.region-a.domain.com
   ```
4. Example call from the command line to exclude indicators for `puppet_status_check::infra_summary`:
   ```shell
   bolt plan run puppet_status_check::summary -p '{"indicator_exclusions": ["S0001","S0021"]}'
   ```
5. Example call from the command line to exclude indicators for `puppet_status_check::agent_summary`:
   ```shell
   bolt plan run puppet_status_check::summary -p '{"indicator_exclusions": ["AS001"]}'
   ```

## Reference

### Facts

#### puppet_status_check_role

This fact is used to determine which status checks are included on an infrastructure node. Classify the `puppet_status_check` module with a `role` parameter to change the role.

| Role     | Description |
| -------- | - |
| primary  | The node hosts a puppetserver, puppetdb, database, and certificate authority |
| compiler | The node hosts a puppetserver and puppetdb |
| postgres | The node hosts a database |
| agent    | The node runs a puppet agent service |

_The role is `agent` by default._

#### puppet_status_check

This fact is confined to run on infrastructure nodes only.

Refer to the table below for next steps when any indicator reports a `false`.

As this module was derived from the [Puppet Enterprise status check module][6], links within the _Self-service steps_ below may reference [Puppet Enterprise][7] specific solutions. The goal over time is to eventually update these to include Open Source Puppet as well.

| Indicator ID | Description                                                                        | Self-service steps                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
|--------------|------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| S0001        | The puppet service is running on agents                            | See [documentation][100] |
| S0003        | Infrastructure components are running in noop                      | Do not routinely configure noop on infrastructure nodes, as it prevents the management of key infrastructure settings. [Disable this setting on infrastructure components.][103] |
| S0004        | Puppet Server status endpoint is returning any errors              | Execute `puppet infrastructure status`.  Which ever service returns in a state that is not running, examine the logging for that service to indicate the fault. |
| S0005        | Certificate authority (CA) cert expires in the next 90 days        | Install the [puppetlabs-ca_extend][104] module and follow steps to extend the CA cert. |
| S0006        | Puppet metrics collector is enabled and collecting metrics.                       | Metrics collector is a tool that lets you monitor a installation. If it is not enabled, [enable it.][105] |
| S0007        | There is at least 20% disk free on the PostgreSQL data partition   | Determines if growth is slow and expected within the TTL of your data. If there's an unexpected increase, use this article to [troubleshoot PuppetDB][106] |
| S0008        | There is at least 20% disk free on the codedir data partition      | This can indicate you are deploying more code from the code repo than there is space for on the infrastructure components, or that something else is consuming space on this partition. Run `puppet config print codedir`, check that codedir partition indicated has enough capacity for the code being deployed, and check that no other outside files are consuming this data mount. |
| S0009        | Puppetserver service is running and enabled                        | Checks that the service can be started and enabled by running `puppet resource service pe-puppetserver ensure=running`, examines `/var/log/puppetlabs/puppetserver/puppetserver.log` for failures. |
| S0010        | Puppetdb service is running and enabled                            | Checks that the service can be started and enabled by running `puppet resource service pe-pupeptdb ensure=running`, examines `/var/log/puppetlabs/puppetdb/puppetdb.log` for failures. |
| S0011        | Postgres service is running and enabled                            | Checks that the service can be started and enabled by running `puppet resource service pe-postgres ensure=running`, examines `/var/log/puppetlabs/postgresql/<postgresversion>/postgresql-<today>.log` for failures. |
| S0012        | Puppet produced a report during the last run interval              | [Troubleshoot Puppet run failures.][107] |
| S0013        | The catalog was successfully applied during the last Puppet run    | [Troubleshoot Puppet run failures.][108] |
| S0014        | Anything in the command queue is older than a Puppet run interval  | This can indicate that the PuppetDB performance is inadequate for incoming requests. Review PuppetDB performance. [Use metrics to pinpoint the issue.][109] |
| S0015        | The agent host certificate is expiring in the next 90 days         | Puppet Enterprise has built in functionalilty to regenerate infrastructure certificates, see the following [documentation][110] |
| S0016        | There are no _OutOfMemory_ errors in the Puppetserver log          | [Increase the Java heap size for that service.][111] |
| S0017        | There are no _OutOfMemory_ errors in the Puppetdb log              | [Increase the Java heap size for that service.][112] |
| S0019        | There sufficient jRubies available to serve agents                 | Insufficient jRuby availability results in queued puppet agents and overall poor system performance. There can be many causes: [Insufficient server tuning for load][113], [a thundering herd][114], and [insufficient system resources for scale.][115] |
| S0021        | There is at least 10% free system memory                           | Ensure your system hardware availability matches the [recommended configuration][116], note this assumes no third-party software using significant resources, adapt requirements accordingly for third-party requirements. Examine metrics from the server and determine if the memory issue is persistent |
| S0023        | Certificate authority CRL does not expire within the next 90 days  | The solution is to reissue a new CRL from the Puppet CA, note this will also remove any revoked certificates. To do this follow the instructions in [this module][117] |
| S0024        | Files in the puppetdb discard directory more than 1 week old       | Recent files indicate PuppetDB may have in issue processing incoming data. See [this article][118] for more information. |
| S0025        | The host copy of the CRL does not expire in the next 90 days       | If S0023 on the primary role is also false, use the resolution steps in S0023. If S0023 on the primary is true, follow [this article][119] |
| S0026        | The puppetserver JVM Heap-Memory is set to an efficient value      | Due to an oddity in how JVM memory is utilized, most Java applications are unable to consume heap memory between ~31GB and ~48GB. If the heap memory set within this value, reduce it to efficiently allocate server resources. See [this article][120] for more information. |
| S0027        | The puppetdb JVM Heap-Memory is set to an efficient value          | Due to an oddity in how JVM memory is utilized, most Java applications are unable to consume heap memory between ~31GB and ~48GB. If the heap memory set within this value, reduce it to efficiently allocate server resources. See [this article][121] for more information. |
| S0029        | Postgresql connections are less than 90% of the configured maximum | First determine the need to increase connections, evaluate if this message appears on every puppet run, or if idle connections from recent component restarts may be to blame. If persistent, impact is minimal unless you need to add more components such as Compilers or Replicas, if you plan to increase the number of components on your system, increase the `max_connections` value. Consider also increasing `shared_buffers` if that is the case as each connection consumes RAM. |
| S0030        | Puppet is configured with `use_cached_catalog` set to true         | It is recommended to not enable `use_cached_catalog`. Enabling prevents the enforcement of key infrastructure settings. [See our documentation for more information][122] |
| S0033        | Hiera version 5 is in use                                          | Upgrading to Hiera 5 [offers major advantages][123] |
| S0034        | Puppetserver been upgraded within the last year                    | [Upgrade your instance.][124] |
| S0035        | `puppet module list` is not returning any warnings                 | Run `puppet module list --debug` and resolve the issues shown. The Puppetfile does NOT include Forge module dependency resolution. Ensure that every module needed for all of the specified modules to run is included. Refer to [managing environment content with a Puppetfile][125] and refer individual modules on [the Puppet forge][126] for dependency information. |
| S0036        | Puppetserver configured `max-queued-requests` is less than 151     | [The maximum value for `jruby_puppet_max_queued_requests` is 150][127] |
| S0038        | Number of environments under `$codedir/environments` is less than 100 | Having a large number of code environments can negatively affect Puppet Server performance. See [Configuring Puppet Server documentation][128] for more information. Remove any environments that are not required. If all are required you can ignore this warning. |
| S0039        | Puppetserver has not reached the configured `queue-limit-hit-rate` | See the [max-queued-requests article][129] for more information. |
| S0045        | Puppetserver is configured with a reasonable number of JRubies     | Having too many can reduce the amount of heap space available to puppetserver and cause excessive garbage collections, reducing performance. While it is possible to increase the heap along with the number of JRubies, we have observed diminishing returns with more than 12 JRubies. Therefore an upper limit of 12 is recommended with between 1 and 2gb of heap memory allocated for each. |
| AS001        | The agent host certificate is not expiring in the next 90 days     | Use a puppet query to find expiring host certificates. `puppet query 'inventory[certname] { facts.puppet_status_check.AS001 = false }'` |
| AS003        | If set, the certname is not in the wrong section of puppet.conf    | The certname should only be placed in the [main] section to prevent unforeseen issues with the puppet agent. Refer to the documentation on [configuring the certname][130]. |
| AS004        | The hosts copy of the CRL does not expire in the next 90 days      | Use the resolution steps in S0023. If S0023 on the primary role is true, [follow this article][131] |

## How to report an issue or contribute to the module

 If you have a reproducible bug, you can [open an issue directly in the GitHub issues page of the module][8]. We also welcome PR contributions to improve the module. [Please see further details about contributing][9].

[1]: https://github.com/puppetlabs/puppetdb-cli
[2]: https://puppet.com/docs/puppet/latest/hiera_intro.html
[3]: https://puppet.com/docs/puppet/latest/hiera_config_yaml_5.html
[4]: https://puppet.com/docs/bolt/latest/hiera.html#outside-apply-blocks
[5]: https://puppet.com/bolt
[6]: https://forge.puppet.com/modules/puppetlabs/pe_status_check
[7]: https://www.puppet.com/products/puppet-enterprise
[8]: https://github.com/puppetlabs/puppetlabs-puppet_status_check/issues
[9]: https://puppet.com/docs/puppet/latest/contributing.html#contributing_changes_to_module_repositories
[100]: https://portal.perforce.com/s/article/Why-is-puppet-service-not-running
[101]: https://portal.perforce.com/s/article/4442390587671
[102]: https://portal.perforce.com/s/article/7606830611223
[103]: https://puppet.com/docs/puppet/latest/configuration.html#noop
[104]: https://forge.puppet.com/modules/puppetlabs/ca_extend
[105]: https://puppet.com/docs/pe/latest/getting_support_for_pe.html#puppet_metrics_collector
[106]: https://support.puppet.com/hc/en-us/articles/360056219974
[107]: https://puppet.com/docs/pe/latest/run_puppet_on_nodes.html#troubleshooting_puppet_run_failures
[108]: https://puppet.com/docs/pe/latest/run_puppet_on_nodes.html#troubleshooting_puppet_run_failures
[109]: https://support.puppet.com/hc/en-us/articles/231751308
[110]: https://puppet.com/docs/pe/2021.5/regenerate_certificates.html#regenerate_certificates
[111]: https://support.puppet.com/hc/en-us/articles/360015511413
[112]: https://support.puppet.com/hc/en-us/articles/360015511413
[113]: https://support.puppet.com/hc/en-us/articles/360013148854
[114]: https://support.puppet.com/hc/en-us/articles/215729277
[115]: https://puppet.com/docs/pe/latest/hardware_requirements.html#hardware_requirements
[116]: https://puppet.com/docs/pe/latest/hardware_requirements.html#hardware_requirements
[117]: https://forge.puppet.com/modules/m0dular/crl_truncate
[118]: https://portal.perforce.com/s/article/files-in-the-puppetdb-discard-directory
[119]: https://support.puppet.com/hc/en-us/articles/7631166251415
[120]: https://support.puppet.com/hc/en-us/articles/360015511413
[121]: https://support.puppet.com/hc/en-us/articles/360015511413
[122]: https://puppet.com/docs/puppet/latest/configuration.html#use-cached-catalog
[123]: https://puppet.com/docs/puppet/latest/hiera_migrate
[124]: https://www.puppet.com/docs/puppet/latest/upgrade.html
[125]: https://puppet.com/docs/pe/latest/puppetfile.html
[126]: https://forge.puppet.com
[127]: https://support.puppet.com/hc/en-us/articles/115003769433
[128]: https://www.puppet.com/docs/puppet/latest/server/tuning_guide
[129]: https://support.puppet.com/hc/en-us/articles/115003769433
[130]: https://puppet.com/docs/puppet/8/configuration.html#certname
[131]: https://support.puppet.com/hc/en-us/articles/7631166251415
