#!/usr/bin/env ruby
#
# Graylog2 Server Alive Check
# ===
#
# This plugin checks if the Graylog2 Server is alive using the REST API
#
# Copyright 2015 Swift Networks
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'json'
require 'rest_client'

class CheckGraylog2Alive < Sensu::Plugin::Check::CLI
  option :host,
         description: 'Graylog2 host',
         short: '-h',
         long: '--host HOST',
         default: 'localhost'

  option :username,
         description: 'Graylog2 username',
         short: '-u',
         long: '--username USERNAME',
         default: 'admin',
         required: true

  option :password,
         description: 'Graylog2 password',
         short: '-p',
         long: '--password PASSWORD',
         required: true

  option :port,
         description: 'RabbitMQ API port',
         short: '-P',
         long: '--port PORT',
         default: '12900'

  def run
    res = vhost_alive?

    if res['status'] == 'ok'
      ok res['message']
    elsif res['status'] == 'critical'
      critical res['message']
    else
      unknown res['message']
    end
  end

  def vhost_alive?
    host     = config[:host]
    port     = config[:port]
    username = config[:username]
    password = config[:password]

    begin
      resource = RestClient::Resource.new "http://#{host}:#{port}/system", username, password
      # Attempt to parse response (just to trigger parse exception)
      _response = JSON.parse(resource.get)
      if _response['lifecycle'] == 'running' and _response['is_processing'] and _response['lb_status'] == 'alive'
        { 'status' => 'ok', 'message' => 'Graylog2 server is alive' }
      else
        { 'status' => 'critical', 'message' => 'Graylog2 server is online but not processing' }
      end
    rescue Errno::ECONNREFUSED => e
      { 'status' => 'critical', 'message' => e.message }
    rescue => e
      { 'status' => 'unknown', 'message' => e.message }
    end
  end
end
