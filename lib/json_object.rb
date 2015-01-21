require "json_object/version"
require 'json'
require 'ostruct'

module JsonObject

  class CompatibleOpenStruct < OpenStruct
    attr_accessor :json_parent

    def initialize hash, parent=nil
      @json_parent = parent
      super(hash)
    end
  end

  class << self

    def default_json_object_class= klass
      @default_json_object_class = klass
    end

    def default_json_object_class
      @default_json_object_class || JsonObject::CompatibleOpenStruct
    end
  end


  #callback runs when module is included in another module/class
  def self.included klass
    klass.extend ClassMethods
  end

  #lets keep the name unique enough that it won't conflict
  attr_reader :json_object_hash

  def json_object_hash= hash
   @json_object_hash = hash || {}
  end

  module ClassMethods

    # options
    # * rename
    def json_value_accessor attribute, opts={}
      method_name = opts[:name] || attribute
      cached_method_results_name = "@#{method_name}_cached"
      default_value = opts[:default] || nil
      proc_provided = opts[:proc] || nil
      define_method method_name do
        return instance_variable_get(cached_method_results_name) if instance_variable_defined?(cached_method_results_name)
        instance_variable_set("@#{method_name}_cached", begin
          value = json_object_hash[attribute.to_s] || default_value
          proc_provided ? proc_provided.call(self, value) : value
        end)
      end
    end

    def json_value_accessors *args
      args.each do |values|
        json_value_accessor *Array(values)
      end
    end

    def create_json_accessor_method method_name, &block
      define_method method_name do
        return instance_variable_get(cached_method_results_name) if instance_variable_defined?(cached_method_results_name)
        instance_variable_set("@#{method_name}_cached", begin
          block.yield
        end)
      end
    end

    private :create_json_accessor_method

    def json_object_accessor attribute, opts={}
      method_name = opts[:name] || attribute
      cached_method_results_name = "@#{method_name}_cached"
      klass = opts.fetch(:class, JsonObject.default_json_object_class)
      define_method method_name do
        return instance_variable_get(cached_method_results_name) if instance_variable_defined?(cached_method_results_name)
        instance_variable_set("@#{method_name}_cached", begin
          value_for_attribute = json_object_hash[attribute.to_s]
          methods_value = if value_for_attribute.is_a? Array
            value_for_attribute.inject([]) do |classes, hash|
              classes << klass.new(hash, self)
            end
          else
            klass.new(value_for_attribute, self)
          end
        end)
      end
    end
  end

  class Base
    include JsonObject

    attr_reader :json_parent

    def initialize hash, parent=nil
      self.json_object_hash = hash
      @json_parent = parent
    end
  end
end
