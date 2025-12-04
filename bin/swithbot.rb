require 'switchbot'

client = Switchbot::Client.new(ENV['SWITCHBOT_TOKEN'], ENV['SWITCHBOT_SECRET'])
device_id = ENV['SWITCHBOT_DEVICE_ID']
expected = ARGV[0]

if expected == 'on'
  client.device(device_id).on
else
  client.device(device_id).off
end

