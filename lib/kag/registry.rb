require 'thread'

module KAG
  class Listener
    class << self
      extend Forwardable
      def_delegators "KAG::Registry.root", :[], :[]=

      def delete_registered(x)
        KAG::Registry.root.delete(x)
      end
    end

    def registered
      KAG::Registry.root.names
    end


    def clear_registry
      KAG::Registry.root.clear
    end
  end

  class Registry
    class << self
      attr_reader :root
    end

    def initialize
      @registry = {}
      @registry_lock = Mutex.new
    end

    # Register an Actor
    def []=(name, actor)
      @registry_lock.synchronize do
        @registry[name.to_sym] = actor
      end
    end

    # Retrieve an actor by name
    def [](name)
      @registry_lock.synchronize do
        @registry[name.to_sym]
      end
    end

    alias_method :get, :[]
    alias_method :set, :[]=

    def delete(name)
      @registry_lock.synchronize do
        @registry.delete name.to_sym
      end
    end

    # List all registered actors by name
    def names
      @registry_lock.synchronize { @registry.keys }
    end

    # removes and returns all registered actors as a hash of `name => actor`
    # can be used in testing to clear the registry
    def clear
      hash = nil
      @registry_lock.synchronize do
        hash = @registry.dup
        @registry.clear
      end
      hash
    end

    # Create the default registry
    @root = new
  end
end
