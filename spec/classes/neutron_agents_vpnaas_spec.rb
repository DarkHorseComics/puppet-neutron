#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for neutron::agents::vpnaas class
#

require 'spec_helper'

describe 'neutron::agents::vpnaas' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :params do
    {}
  end

  let :default_params do
    { :package_ensure              => 'present',
      :enabled                     => true,
      :vpn_device_driver           => 'neutron.services.vpn.device_drivers.ipsec.OpenSwanDriver',
      :ipsec_status_check_interval => '60'
    }
  end


  shared_examples_for 'neutron vpnaas agent' do
    let :p do
      default_params.merge(params)
    end

    it { should contain_class('neutron::params') }

    it_configures 'openswan vpnaas_driver'

    it 'configures vpnaas_agent.ini' do
      should contain_neutron_vpnaas_agent_config('vpnagent/vpn_device_driver').with_value(p[:vpn_device_driver]);
      should contain_neutron_vpnaas_agent_config('ipsec/ipsec_status_check_interval').with_value(p[:ipsec_status_check_interval]);
    end

    it 'installs neutron vpnaas agent package' do
      if platform_params.has_key?(:vpnaas_agent_package)
        should contain_package('neutron-vpnaas-agent').with(
          :name   => platform_params[:vpnaas_agent_package],
          :ensure => p[:package_ensure]
        )
        should contain_package('neutron').with_before(/Package\[neutron-vpnaas-agent\]/)
        should contain_package('neutron-vpnaas-agent').with_before(/Neutron_vpnaas_agent_config\[.+\]/)
      else
        should contain_package('neutron').with_before(/Neutron_vpnaas_agent_config\[.+\]/)
      end
    end

    it 'configures neutron vpnaas agent service' do
      should contain_service('neutron-vpnaas-service').with(
        :name    => platform_params[:vpnaas_agent_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]'
      )
    end
  end

  shared_examples_for 'openswan vpnaas_driver' do
    it 'installs openswan packages' do
      if platform_params.has_key?(:vpnaas_agent_package)
        should contain_package('openswan').with_before('Package[neutron-vpnaas-agent]')
      end
      should contain_package('openswan').with(
        :ensure => 'present',
        :name   => platform_params[:openswan_package]
      )
    end
  end


  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :openswan_package   =>  'openswan',
        :vpnaas_agent_package => 'neutron-plugin-vpn-agent',
        :vpnaas_agent_service => 'neutron-vpnaas-agent' }
    end

    it_configures 'neutron vpnaas agent'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :openswan_package   => 'openswan',
        :vpnaas_agent_service => 'neutron-vpnaas-agent'}
    end

    it_configures 'neutron vpnaas agent'
  end
end
