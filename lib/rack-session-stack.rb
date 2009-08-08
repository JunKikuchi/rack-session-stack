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
        unless sid && session
          env['rack.errors'].puts(
            "Session '#{sid.inspect}' not found, initializing..."
          ) if $VERBOSE && !sid.nil?
          sid, session = generate_sid, {}
          @stack.create(sid, session)
        end
        session.instance_variable_set('@old', {}.merge(session))
        return [sid, session]
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      def set_session(env, sid, new_session, options)
        @mutex.lock if env['rack.multithread']
        session = @stack[sid] || {}
        if options[:renew] || options[:drop]
          @stack.delete(sid)
          return false if options[:drop]
          sid = generate_sid
          @stack.create(sid, session)
        end
        old_session = new_session.instance_variable_get('@old') || {}
        session = merge_sessions(sid, old_session, new_session, session)
        @stack[sid] = session
        return sid
      ensure
        @mutex.unlock if env['rack.multithread']
      end

      def merge_sessions(sid, old, new, cur=nil)
        cur ||= {}

        unless old.is_a?(Hash) && new.is_a?(Hash)
          warn('Bad old or new sessions provided.')
          return cur
        end

        delete = old.keys - new.keys
        if $VERBOSE && !delete.empty?
          warn("//@#{sid}: delete #{delete*','}")
        end
        delete.each{|k| cur.delete k }

        update = new.keys.select{|k| new[k] != old[k] }
        if $VERBOSE && !update.empty?
          warn("//@#{sid}: update #{update*','}")
        end
        update.each{|k| cur[k] = new[k] }

        cur
      end
      private :merge_sessions

      class Base
        PARAMS = {}

        def initialize(params={}, fallback=nil)
          @params, @fallback = self.class::PARAMS.merge(params), fallback
        end

        def key?(sid)
          @fallback && @fallback.key?(sid)
        end

        def create(sid, session)
          @fallback && @fallback.create(sid, session)
        end

        def delete(sid)
          @fallback && @fallback.delete(sid)
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

      autoload :Memcache, 'rack-session-stack/memcache'
      autoload :Sequel,   'rack-session-stack/sequel'

      module RAWS
        autoload :SDB, 'rack-session-stack/raws/sdb'
      end
    end
  end
end
