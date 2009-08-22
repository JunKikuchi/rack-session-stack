require 'rack/session/abstract/id'
require 'uuidtools'

module Rack
  module Session
    class Stack < Abstract::ID
      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge(:stack => nil)

      def initialize(app, options={})
        super
        @stack = @default_options[:stack]
      end

      def generate_sid
        UUIDTools::UUID.random_create
      end

      def get_session(env, sid)
        unless sid && session = @stack[sid]
          @stack.create(sid = generate_sid, session = {})
        end

        session.instance_variable_set('@old', {}.merge(session))
      
        return [sid, session]
      end

      def set_session(env, sid, session, options)
        if options[:drop]
          @stack.delete(sid)
          return nil
        end

        if options[:renew]
          @stack.delete(sid)
          @stack.create(sid = generate_sid, session)
        else
          old = session.instance_variable_get('@old') || {}
          @stack[sid] = session if session != old
        end

        return sid
      end

      class Base
        PARAMS = {}

        def initialize(params={}, fallback=nil)
          @params, @fallback = self.class::PARAMS.merge(params), fallback
        end

        def create(sid, session)
          @fallback && @fallback.create(sid, session)
        end

        def delete(sid)
          @fallback && @fallback.delete(sid)
        end

        def [](sid)
          @fallback && @fallback[sid]
        end

        def []=(sid, session)
          @fallback && (@fallback[sid] = session)
          session
        end
      end

      autoload :Memcache, 'rack-session-stack/memcache'
      autoload :Sequel,   'rack-session-stack/sequel'

      module RAWS
        autoload :SDB, 'rack-session-stack/raws/sdb'
      end
    end
  end
end
