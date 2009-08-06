require 'raws'
require 'time'

class Rack::Session::Stack::RAWS::SDB < Rack::Session::Stack::Base
  attr_reader :mutex, :pool
  PARAMS = {:domain => nil}

  def initialize(params={}, fallback=nil)
    super
    @pool = ::RAWS::SDB[@params[:domain]]
  end

  def key?(sid)
    @pool.get(sid) || super
  end

  def [](sid)
    if data = @pool.get(sid)
      Marshal.load(data['session'].unpack("m*").first)
    else
      super
    end
  end

  def []=(sid, session)
    @pool.put(
      sid,
      {
        'session' => [Marshal.dump(session)].pack('m*'),
        'updated' => Time.now.utc.iso8601
      },
      'session',
      'updated'
    )
    super
  end
end
