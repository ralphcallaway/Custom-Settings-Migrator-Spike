require 'rubygems'
require 'databasedotcom'
require 'yaml'

module Custom_Settings_Migrator
  
  class Client
  
    def initialize(options) 
      @src_username = options[:src_username]
      @src_password = options[:src_password]
      @src_host = options[:src_host]
      @target_username = options[:target_username]
      @target_password = options[:target_password]
      @target_host = options[:target_host]
    end
  
    def migrate()

      # create src client
      src_client = Databasedotcom::Client.new("databasedotcom.yml")
      src_client.host = @src_host
      src_client.authenticate :username => @src_username, :password => @src_password

      # query custom settings
      custom_settings = src_client.describe_sobjects.select { |obj| obj["customSetting"] }.collect { |obj| obj["name"]}
      puts "custom_settings: #{custom_settings.inspect}"

      # gather creatable fields
      fields_to_query = {}
      custom_settings.each do |custom_setting|
        fields_to_query[custom_setting] = []
        describe = src_client.describe_sobject custom_setting
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
        records = src_client.query query_string
        puts "#{custom_setting} records: #{records}"
        data[custom_setting] = records
      end

      # create target client
      target_client = Databasedotcom::Client.new("databasedotcom.yml")
      target_client.host = @target_host
      target_client.authenticate :username => @target_username, :password => @target_password

      # push records to new org
      data.each do |custom_setting, records|
        if records
          records.each do |record|
            if record.SetupOwnerId.start_with?('00D')
              record.SetupOwnerId = target_client.org_id
            end
            record.client = target_client
            record = record.save
          end
        end
      end
    end
  
  end

end