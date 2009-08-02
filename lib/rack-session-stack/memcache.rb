require 'memcache'

class Rack::Session::Stack::Memcache < Rack::Session::Stack::Base
  attr_reader :mutex, :pool
  PARAMS = {:server => 'localhost:11211'}

  def initialize(params={}, fallback=nil)
    super
    @pool = ::MemCache.new(@params[:server], @params)
    raise 'No memcache servers' unless @pool.servers.any? { |s| s.alive? }
  end

  def key?(sid)
    @pool.get(sid, true)
  end

  def [](sid)
    if data = @pool.get(sid)
      data
    else
      super
    end
  end

  def []=(sid, session)
    @pool.set(sid, session, 0)
    super
  end
end
