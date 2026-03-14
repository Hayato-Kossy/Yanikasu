require 'minitest/autorun'
require 'stringio'
require 'tmpdir'

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'request'
require 'response'
require 'router'
require 'db'
require 'yanikasu'
require_relative '../middleware/cors'
