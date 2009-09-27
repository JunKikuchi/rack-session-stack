require 'raws'
require 'time'

class Rack::Session::Stack::RAWS::SDB < Rack::Session::Stack::Base
  attr_reader :pool
  PARAMS = {:domain => nil}

  def initialize(params={}, fallback=nil)
    super
    @pool = ::RAWS::SDB[@params[:domain]]
  end

  def create(sid, session)
    @pool.put(
      sid,
      {
        'session' => [Marshal.dump(session)].pack('m*'),
        'created' => Time.now.utc.iso8601,
        'updated' => Time.now.utc.iso8601
      },
      'session',
      'created',
      'updated'
    )
    super
  end

  def delete(sid)
    @pool.delete(sid)
    super
  end

  def store(sid, session)
    @pool.put(
      sid,
      {
        'session' => [Marshal.dump(session)].pack('m*'),
        'updated' => Time.now.utc.iso8601
      },
      'session',
      'updated'
    )
    session
  end

  def [](sid)
    if data = @pool.get(sid)
      Marshal.load(data['session'].unpack("m*").first)
    else
      if data = super
        create(sid, data)
      end
    end
  end

  def []=(sid, session)
    store(sid, session)
    super
  end
end
