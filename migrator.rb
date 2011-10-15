require 'rubygems'
require 'databasedotcom'
require 'yaml'

credentials = YAML.load_file("passwords.yml")
credentials.symbolize_keys!

username1 = credentials[:username1]
password1 = credentials[:password1]

username2 = credentials[:username2]
password2 = credentials[:password2]

# create src client
client1 = Databasedotcom::Client.new("databasedotcom.yml")
client1.authenticate :username => username1, :password => password1

# query custom settings
custom_settings = client1.describe_sobjects.select { |obj| obj["customSetting"] }.collect { |obj| obj["name"]}
puts "custom_settings: #{custom_settings.inspect}"

# gather creatable fields
fields_to_query = {}
custom_settings.each do |custom_setting|
  fields_to_query[custom_setting] = []
  describe = client1.describe_sobject custom_setting
  describe['fields'].each do |field|
    fields_to_query[custom_setting].push field['name'] if field['createable']
  end
end
puts "fields_to_query: #{fields_to_query.inspect}"

# query data
data = {}
fields_to_query.each do |custom_setting, fields|
  fields_string = ''
  fields.each { |field| fields_string += ', ' + field }
  fields_string = fields_string[2, fields_string.length] # trim leading ', '
  query_string = 'select ' + fields_string + ' from ' + custom_setting
  puts "#{custom_setting} query: #{query_string}"
  records = client1.query query_string
  puts "#{custom_setting} records: #{records}"
  data[custom_setting] = records
end

# create target client
client2 = Databasedotcom::Client.new("databasedotcom.yml")
client2.host = 'test.salesforce.com'
client2.authenticate :username => username2, :password => password2

# push records to new org
data.each do |custom_setting, records|
  if records
    records.each do |record|
      if record.SetupOwnerId.start_with?('00D')
        record.SetupOwnerId = client2.org_id
      end
      record.client = client2
      record = record.save
    end
  end
end