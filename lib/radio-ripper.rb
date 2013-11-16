# dependencies
require 'rubygems'
require 'active_support/all'
require 'awesome_print'

CONFIG =  HashWithIndifferentAccess.new(
            YAML.load_file(
              File.expand_path("../../config/settings.yml", __FILE__)
            )
          )

# app
require 'stations/wkcr'

# configure/init
# ...

