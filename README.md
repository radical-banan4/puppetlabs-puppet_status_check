# puppetlabs-self_service


1. [Description](#description)
1. [Setup - The basics of getting started with self_service](#setup)
    * [What self_service affects](#what-self_service-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with self_service](#beginning-with-self_service)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - what to do when a indicator repors a fault](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

puppetlabs-self_service aims to provide a mechnism to alert the end-user when Puppet Enterprise is not in an ideal state.
It uses a pre-set indicators and has a simplified output that directs the end-user to next steps for resolution.

Users of the tool should expect greater ability to provide the self served resolutions, as well as shorter incident resolution times with Puppet Enterprise Support due to higher quality information available to support cases.


## Setup

### What self_service affects

This module installs a structured fact named self_service, which contains an array of key pairs tha simply output an indicator ID and a boolean value. 

### Setup Requirements

Plugin-Sync should be enabled to deliver the facts this module requires

### Beginning with self_service

puppetlabs-self_service is primarly provides the indicators by means of facts so installing the module and allowing plugin sync to occur will allow the module to start functioning

## Usage


The Facts contained in this module can be used for direct consumption by monitoring tools such as Splunk, any element in the structured fact `self_service` reporting as "false" indicates a fault state in Puppet Enterprise.
When any of the elements reports as false, the incident ID should be looked up in the reference section for next steps

Alternativly assigning the class self_service to the infrastructure  Will "Notify" on Each Puppet run if any of the indicators are in a fault state.

### Class Delcaration *Optional.*

To activate the notification functions of this module, classify your Puppet Infrastructure  with the self_service class using your preferred classification method. Below is an example using site.pp.

```
node 'node.example.com' {
  include self_service
}
```

While the entirity of the default indictors should be reported on for maximum coverage, it may be nessary to make exceptions for your particular environment.
to do this classify the array parameter self_service_indicators with an inclusive list of all indicators you do want to report on.

```
class { 'self_service':
  self_service_indicators             => ['S0001','S0003','S0003','S0004'],
}
```


## Reference

This section should be referred to for next steps when any indicator reports a fault

| Indicator ID | Self Service Steps | What to Include in a Support Ticket |
|--------------|--------------------|-------------------------------------|
| S0001        |                    |                                     |
| S0002        |                    |                                     |
| S0003        |                    |                                     |
| S0004        |                    |                                     |
| S0005        |                    |                                     |
| S0006        |                    |                                     |
| S0007        |                    |                                     |
| S0008        |                    |                                     |



## Limitations


## Development


