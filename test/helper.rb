require 'pry/test/helper'

unless Object.const_defined? 'PryNote'
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry-note'
end

def cleanup_file(file_name)
  f = File.expand_path(file_name)
  File.unlink(f) if File.exists?(f)
  yield
ensure
  File.unlink(f) if File.exists?(f)
end
