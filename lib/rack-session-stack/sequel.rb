require 'sequel'

class Rack::Session::Stack::Sequel < Rack::Session::Stack::Base
  PARAMS = {:dataset => nil}

  def initialize(params={}, fallback=nil)
    super
    @pool = @params[:dataset]
  end

  def key?(sid)
    @pool.filter('sid = ?', sid).count == 1 || super
  end

  def create(sid, session)
    @pool.insert(
      :sid     => sid,
      :session => [Marshal.dump(session)].pack('m*'),
      :created => Time.now.utc,
      :updated => Time.now.utc
    )
    super
  end

  def delete(sid)
    if data = @pool.filter('sid = ?', sid).first
      data.delete
    end
    super
  end

  def [](sid)
    if data = @pool.filter('sid = ?', sid).first
      Marshal.load(data[:session].unpack("m*").first)
    else
      super
    end
  end

  def []=(sid, session)
    @pool.filter('sid = ?', sid).update(
      :session => [Marshal.dump(session)].pack('m*'),
      :updated => Time.now.utc
    )
    super
  end
end
