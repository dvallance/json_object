require "json_object/version"
require 'json'
require 'ostruct'

module JsonObject

  class JsonOpenStruct < OpenStruct
    include JsonObject

    def self.init_from_json_hash hash, parent=nil
      obj = new(hash)
      obj.json_parent = parent
      obj.json_hash = hash
      obj
    end
  end

  class << self

    def default_json_object_class= klass
      @default_json_object_class = klass
    end

    def default_json_object_class
      @default_json_object_class || JsonObject::JsonOpenStruct
    end
  end


  #callback runs when module is included in another module/class
  def self.included klass
    klass.extend ClassMethods
  end

  attr_accessor :json_parent

  attr_reader :json_hash

  def json_hash= hash
   @json_hash = hash || {}
  end

  module ClassMethods

    def create_value_accessor_method attribute, opts={}, &block
      method_name = opts[:name] || attribute
      cached_method_results_name = "@#{method_name}_cached"
      define_method method_name  do
        return instance_variable_get(cached_method_results_name) if instance_variable_defined?(cached_method_results_name)
        instance_variable_set("@#{method_name}_cached", begin
          block.yield self
        end)
      end
    end

    private :create_value_accessor_method

    def json_value_accessor attribute, opts={}
      default_value = opts[:default]
      proc_provided = opts[:proc]
      create_value_accessor_method attribute, opts do |obj|
        value = obj.json_hash[attribute.to_s]
        value = default_value if value.nil?
        proc_provided ? proc_provided.call(obj, value) : value
      end
    end

    def json_value_accessors *args
      args.each do |values|
        json_value_accessor *Array(values)
      end
    end

    def json_object_accessor attribute, opts={}
      klass = opts.fetch(:class, JsonObject.default_json_object_class)
      create_value_accessor_method attribute, opts do |obj|
        value_for_attribute = obj.json_hash[attribute.to_s]
        methods_value = if value_for_attribute.is_a? Array
          value_for_attribute.inject([]) do |classes, hash|
            classes << klass.init_from_json_hash(hash, obj)
          end
        else
          value_for_attribute.nil? ? nil : klass.init_from_json_hash(value_for_attribute, obj)
        end
      end
    end
  end

  class Base
    include JsonObject

    def self.init_from_json_hash hash, parent=nil
      obj = new()
      obj.json_parent = parent
      obj.json_hash = hash
      obj
    end
=begin
    def initialize hash, parent=nil
      self.json_hash = hash
      @json_parent = parent
    end
=end
  end
end
