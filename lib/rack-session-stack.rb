require 'rack/session/abstract/id'

module Rack
  module Session
    class Stack < Abstract::ID
      attr_reader :mutex
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge :stack => nil

      def initialize(app, options={})
        super
        @mutex = Mutex.new
        @stack = @default_options[:stack]
      end

      def generate_sid
        loop do
          sid = super
          break sid unless @stack.key? sid
        end
      end

      def get_session(env, sid)
        session = @stack[sid] if sid
        @mutex.lock if env['rack.multithread']
        sid, session = generate_sid, {} unless sid && session
        @old = {}.merge(session)
        return [sid, session]
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      def set_session(env, sid, session, options)
        @mutex.lock if env['rack.multithread']
        @stack[sid] = session if @old != session
        return sid
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      class Base
        PARAMS = {}

        def initialize(params={}, fallback=nil)
          @params, @fallback = self.class::PARAMS.merge(params), fallback
        end

        def key?(sid)
          @fallback && @fallback.key?(sid)
        end

        def [](sid)
          session = @fallback && @fallback[sid]
          self[sid] = session if session
        end

        def []=(sid, session)
          @fallback && (@fallback[sid] = session)
          session
        end
      end

      autoload :SDB,      'lib/rack-session-stack/sdb'
      autoload :Memcache, 'lib/rack-session-stack/memcache'
    end
  end
end
