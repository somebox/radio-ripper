require 'curb'
require 'nokogiri'
require 'chronic'
require 'moneta'

require 'stations/wkcr/schedule'
require 'stations/wkcr/show'

module WKCR
  USER_AGENT = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36"
end
