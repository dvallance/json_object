require "json_object/version"
require 'json'
require 'ostruct'

# The intended use of this module is for inclusion in a class, there by giving
# the class the necessary methods to store a JSON Hash and define custom accessors
# to retrieve its values.
#
# @example when including class has a no argument initializer
#   class SomeClass
#     include JsonObject
#   end
#
# @example when the including class has an initializer with arguments
#   class AnotherClass
#     include JsonObject
#
#     def initialize string
#       # does something with string
#     end
#
#     # we must override the default {#create} method as it will call
#     # new() with no arguments on the class by default
#
#     #this is the form it must take
#     def self.create hash, parent=nil
#       # here we imagine getting the initializer string param from the hash
#       obj = new(hash["..."])
#
#       # we must set the json_hash instance variable for proper functionality
#       obj.json_hash = hash
#
#       # optionally we can set the hash_parent variable
#       obj.json_parent = parent
#
#       #finnally we return our new object
#       obj
#     end
#
#     # same as above but using Object#tap for a cleaner implementation
#     def self.create hash, parent=nil
#       new(hash["..."]).tap do |obj|
#         obj.json_hash = hash
#         obj.json_parent = parent
#       end
#     end
#
#   end
module JsonObject

  # A sane default class for use by {ClassMethods#object_accessor} when a custom
  # class is not provided.
  #
  # Simply an OpenStruct object with our JsonObject module included.
  #
  # @see ClassMethods#object_accessor
  class JsonOpenStruct < OpenStruct
    include JsonObject

    # Making sure we set our json_* attributes otherwise
    def self.create hash, parent=nil
      new(hash).tap do |obj|
        obj.json_parent = parent
        obj.json_hash = hash
      end
    end
  end

  # JsonObject class methods
  class << self

    # Allows setting a custom class to replace the default JsonOpenStruct.
    def default_json_object_class= klass
      @default_json_object_class = klass
    end

    # Retrieve a set default class or use our JsonOpenStruct default.
    def default_json_object_class
      @default_json_object_class || JsonObject::JsonOpenStruct
    end

    def create
      Class.new.include(JsonObject)
    end
  end

  # Callback runs when module is included in another module/class.
  #
  # We use this to automatically extend our ClassMethods module in a
  # class that includes JsonObject.
  def self.included klass
    klass.extend ClassMethods
  end

  # Used to aid in nested JsonObject's traversing back through their parents.
  attr_accessor :json_parent

  # Stores the underlying JSON Hash that we wish to then declare accessors for.
  attr_accessor :json_hash

  # Nested JsonObjects might be initalized with new so we account for that by
  # supplying a empty hash default.
  def json_hash= hash
   @json_hash = hash || {}
  end

  # This will be extended when JsonObject is included in a class.
  module ClassMethods

    # Provides a default implementation of this method, which is a required
    # call, used by {#object_accessor}
    #
    # Usable with a class that can be initialized with no arguments e.g. new()
    def create hash, parent=nil
      new().tap do |obj|
        obj.json_parent = parent
        obj.json_hash = hash
      end
    end

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

    # Creates an accessor method to retrieve values from the stored {#json_hash}
    #
    # @param [#to_s] attribute will be used to retrieve a value from {#json_hash} and will be the name of the new accessor method by default
    # @param [Hash] opts
    # @option opts [#to_s] :name Will explicitly set the new accessor method name
    # @option opts [Object] :default If {#json_hash} has no value for the given attribute the default provided will be returned.
    # @option opts [Proc] :proc Allows a supplied proc to return the value from the created accessor method. The proc has access to self and the current value; may be from the :default option if provided.
    def value_accessor attribute, opts={}
      default_value = opts[:default]
      proc_provided = opts[:proc]
      create_value_accessor_method attribute, opts do |obj|
        value = obj.json_hash[attribute.to_s]
        value = default_value if value.nil?
        proc_provided ? proc_provided.call(obj, value) : value
      end
      self
    end


    # Convienience method for defining muiltiple accessors with one call.
    # @example Muiltiple accessors with no options
    #   value_accessors :first_name, :last_name, :age
    #
    # @example Muiltiple accessors with some options
    #   value_accessors [:selected, default: false], [:category, name: :main_category], :age
    #
    # @param args [#to_s, Array<#to_s, [Hash]>]
    def value_accessors *args
      args.each do |values|
        value_accessor *Array(values)
      end
      self
    end

    # Similar to value_accessor.
    #
    # @example Accepting the default object class
    #   object_accessor :address_information
    #
    # @example Assigning a JsonObject class
    #   object_accessor :address_information, class: AddressInformation
    #
    # @param [#to_s] attribute will be used to retrieve the expected hash value from {#json_hash} and will be the name of the new accessor method by default.
    # @param [Hash] opts
    # @option opts [#to_s] :name Will explicitly set the new accessor method name
    def object_accessor attribute, opts={}
      klass = opts.fetch(:class, JsonObject.default_json_object_class)
      create_value_accessor_method attribute, opts do |obj|
        value_for_attribute = obj.json_hash[attribute.to_s]
        methods_value = if value_for_attribute.is_a? Array
          value_for_attribute.inject([]) do |classes, hash|
            classes << klass.create(hash, obj)
          end
        else
          value_for_attribute.nil? ? nil : klass.create(value_for_attribute, obj)
        end
      end
      self
    end
  end

  # Alternative for include JsonObject is to inherit this class
  # @example
  #   class MyClass < JsonObject::Base
  #   end
  class Base
    include JsonObject
  end
end
