require 'rubygems'
require 'databasedotcom'
require 'yaml'
require 'lib/migrator'

# Example passwords.yml
# # lists passwords for use in test
# --- 
#     src_username: 'user1@test.com'
#     src_password: 'password'
#     src_host: 'login.salesforce.com'
#     target_username: 'user2@test.com'
#     target_password: 'password'
#     target_host: 'test.salesforce.com'

credentials = YAML.load_file("passwords.yml")
credentials.symbolize_keys!

# migrate custom settings
client = Custom_Settings_Migrator::Client.new credentials
client.migrate()
