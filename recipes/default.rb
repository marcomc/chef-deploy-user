#!/usr/bin/env ruby
#
# Cookbook Name:: deploy-user
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

ssh_dir_path          = "#{node['deploy_user']['home']}/.ssh"
ssh_known_hosts_path  = "#{ssh_dir_path}/known_hosts"

Chef::Log.debug 'Create the group with the designated GID.'
group node['deploy_user']['group'] do
  gid node['deploy_user']['gid']
end

Chef::Log.debug 'Create the deploy user.'
user node['deploy_user']['user'] do
  gid node['deploy_user']['gid']
  shell node['deploy_user']['shell'] if node['deploy_user']['shell']
  home node['deploy_user']['home'] if node['deploy_user']['home']
  manage_home node['deploy_user']['manage_home']
  action :create
end

Chef::Log.debug 'Lock the user so it cannot be directly logged into.'
user node['deploy_user']['user'] do
  action :lock
end

Chef::Log.debug 'Create the deploy user SSH directory.'
directory ssh_dir_path do
  owner node['deploy_user']['user']
  group node['deploy_user']['gid']
  mode '0700'
  action :create
end

deploy_keys = node['deploy_user']['private_keys'] || []

Chef::Log.debug 'Loop through a data bag and create the SSH private keys'

known_hosts_data_bag  = node['deploy_user']['data_bag']

data_bag(known_hosts_data_bag).each do |bag_item_id|
  bag_item = Chef::EncryptedDataBagItem.load(known_hosts_data_bag, bag_item_id)
  Chef::Log.debug bag_item
  deploy_keys += bag_item['private_keys']
end if node['deploy_user']['data_bag']

deploy_keys.each do |private_key|
  file "#{ssh_dir_path}/#{private_key['filename']}" do
    content private_key['content']
    owner node['deploy_user']['user']
    group node['deploy_user']['gid']
    mode '0400'
    sensitive true
  end
end

Chef::Log.debug 'Create the known hosts file for the deploy user'
file ssh_known_hosts_path do
  owner node['deploy_user']['user']
  group node['deploy_user']['gid']
  mode '0644'
  action :create
end

Chef::Log.debug 'Add the known_host entries.'
node['deploy_user']['ssh_known_hosts_entries'].each do |known_host_entry|
  ssh_known_hosts_entry known_host_entry[:host] do
    path ssh_known_hosts_path
    key_type known_host_entry[:key_type]
    key known_host_entry[:key]
  end
end

Chef::Log.debug 'Allow the deploy user to have sudo.'
sudo 'deploy_permissions' do
  user node['deploy_user']['user']
  defaults ['!requiretty']
  commands node['deploy_user']['commands'] if node['deploy_user']['commands']
  nopasswd true
end
