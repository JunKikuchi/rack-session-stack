require 'memcache'

class Rack::Session::Stack::Memcache < Rack::Session::Stack::Base
  attr_reader :pool
  PARAMS = {:server => 'localhost:11211'}

  def initialize(params={}, fallback=nil)
    super
    @pool = ::MemCache.new(@params[:server], @params)
    raise 'No memcache servers' unless @pool.servers.any? { |s| s.alive? }
  end

  def create(sid, session)
    unless /^STORED/ =~ @pool.add(sid, session)
      raise "Session collision on '#{sid.inspect}'"
    end
  ensure
    super
  end

  def delete(sid)
    @pool.delete(sid)
  ensure
    super
  end

  def [](sid)
    @pool.fetch(sid) do
      super(sid)
    end
  rescue
    super(sid)
  end

  def []=(sid, session)
    @pool.set(sid, session, 0)
  ensure
    super
  end
end
