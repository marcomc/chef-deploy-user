#!/usr/bin/env ruby

Given(/^the test user is "([^"]*)" in the "([^"]*)" group$/) do |user, group|
  `sudo -n groupadd #{group}`
  `sudo useradd -p '' --no-create-home #{user} 2>&1 &`
  `usermod -a -G #{group} #{user} 2>&1 &`
end

Given(/^the "([^"]*)" group has gid of "([^"]*)"$/) do |deployer_group, gid|
  `groupmod -g #{gid} #{deployer_group} 2>&1 &`
end

When(/^I run sudo as "([^"]*)" to "([^"]*)"$/) do |deployer, deploy_user|
  @test_dir = '/etc/foo'
  cmd = "sudo -b -n /bin/mkdir -p #{@test_dir}"
  cmd_prefix = "sudo -n -u #{deployer} sudo -b -n -u #{deploy_user} bash -c"
  @sudo_command = `#{cmd_prefix} '#{cmd}' 2>&1 &`
end

When(/^I run sudo with an authorised command$/) do
  @sudo_dir = '/var/www/test'
  cmd = "sudo mkdir -p #{@sudo_dir}"
  `sudo -n -u #{@deploy_user} bash -c '#{cmd}' 2>&1`
end

When(/^I run sudo with an unauthorised command$/) do
  cmd = 'sudo -n useradd inviqa-test'
  @useradd = `sudo -u #{@deploy_user} bash -c '#{cmd}' 2>&1`
end

Then(/^the command succeeds$/) do
  expect(@sudo_command).not_to match(/sudo.*password.*required.*/)
  dir = ::File.directory?(@test_dir)
  expect(dir).to be_truthy
end

Then(/^the incident is not reported$/) do
  dir = ::File.directory?(@sudo_dir)
  expect(dir).to be_truthy
end

Then(/^the command fails$/) do
  expect(@useradd).to match(/sudo.*password.*required.*/)
end
