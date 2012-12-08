require 'pry/test/helper'

unless Object.const_defined? 'PryNote'
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'pry-note'
end

# Ensure file is deleted before and after block
def cleanup_file(file_name)
  f = File.expand_path(file_name)
  File.unlink(f) if File.exists?(f)
  yield
ensure
  File.unlink(f) if File.exists?(f)
end

Pad = OpenStruct.new
def Pad.clear
  @table = {}
end

# Return any raised exceptino objects inside the block
def capture_exception
  ex = nil
  begin
    yield
  rescue Exception => e
    ex = e
  end
  ex
end
