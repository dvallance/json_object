require_relative 'spec_helper'

include JsonObject

describe JsonObject do

  it "the default json_object_class is correct" do
    JsonObject.default_json_object_class.must_equal CompatibleOpenStruct
  end

  it "we can change the default json_object_class" do
    klass = Class.new()
    JsonObject.default_json_object_class = klass
    JsonObject.default_json_object_class.must_equal klass
    #reset to correct default
    JsonObject.default_json_object_class = CompatibleOpenStruct
  end

  subject { Class.new(Base) }

  describe Base do

    it "creating an instance with a nil hash will create an empty hash" do
      subject.new(nil).json_object_hash.must_be_instance_of Hash
    end
  end

  describe "value_accessors" do

    let(:json) do
      JSON.parse(<<-EOS
        {"an_integer":1,"a_string":"my string","a_boolean":true,"an_array":[1,2,3]}
      EOS
      )
    end

    it "caching is working" do
      subject.json_value_accessor :an_integer
      check = subject.new(json)
      check.instance_variable_defined?("@an_integer_cached").must_equal false
      check.instance_variable_get("@an_integer_cached").must_equal nil
      check.an_integer
      check.instance_variable_defined?("@an_integer_cached").must_equal true
      check.instance_variable_get("@an_integer_cached").must_equal 1
    end

    describe "#json_value_accessor works for data types Integer, String, Boolean and Array" do

      it "integer" do
        subject.json_value_accessor :an_integer
        subject.new(json).an_integer.must_equal 1
      end

      it "string" do
        subject.json_value_accessor :a_string
        subject.new(json).a_string.must_equal "my string"
      end

      it "boolean" do
        subject.json_value_accessor :a_boolean
        subject.new(json).a_boolean.must_equal true
      end

      it "array" do
        subject.json_value_accessor :an_array
        subject.new(json).an_array.must_equal [1,2,3]
      end

      describe "assigning a specific accessor name" do
        it "to one attribute" do
          subject.json_value_accessor :an_integer, name: "new_integer_accessor"
          subject.new(json).methods.must_include :new_integer_accessor
          subject.new(json).new_integer_accessor.must_equal 1
        end

        it "with an existing accessor of the same name and a proc" do
          subject.json_value_accessor :an_integer
          subject.json_value_accessor :an_integer, name: "new_integer_accessor", proc: Proc.new {|obj, value| value * 2 }
          subject.new(json).methods.must_include :new_integer_accessor
          subject.new(json).an_integer.must_equal 1
          subject.new(json).new_integer_accessor.must_equal 2
        end
      end

      it "when a value doesn't exist nil will be found" do
        subject.json_value_accessor :not_there
        subject.new(json).not_there.must_equal nil
      end

      it "we can provide a default value so a nil return can be avoided" do
        subject.json_value_accessor :not_there, default: "my default value"
        subject.new(json).not_there.must_equal "my default value"
      end

      it "we can provide a modifier proc" do
        subject.json_value_accessor :an_integer, proc: Proc.new {|json_object,value| value*2}
        subject.new(json).an_integer.must_equal 2
      end

      it "another modifying proc example showing it works after :default" do
        subject.json_value_accessor :not_there, default: "small", proc: Proc.new {|json_object, value| value.sub('small', 'big')}
        subject.new(json).not_there.must_equal "big"
      end
    end

    describe "#json_value_accessors can be used to define muiltible accessors at a time" do

      it "integer, string, boolean in one line assignment" do
        subject.json_value_accessors :an_integer, :a_string, :a_boolean
        subject.new(json).an_integer.must_equal 1
        subject.new(json).a_string.must_equal "my string"
        subject.new(json).a_boolean.must_equal true
      end

      it "correctly uses options like :name" do
        subject.json_value_accessors :an_integer, [:a_string, name: "custom_name"]
        subject.new(json).methods.must_include :custom_name
        subject.new(json).custom_name.must_equal "my string"
      end

    end
  end

  describe "#json_object_accessor" do

    let(:json) do
      JSON.parse(<<-EOS
        {"an_object":{"id":1, "name":"object one", "enabled":true}, "name":"record one"}
      EOS
      )
    end

    let :object_handler_class do
      Class.new(Base).tap do |obj|
        obj.json_value_accessors :id, :name, :object
      end
    end

    it "caching is working" do
      subject.json_object_accessor :an_object
      check = subject.new(json)
      check.instance_variable_defined?("@an_object_cached").must_equal false
      check.instance_variable_get("@an_object_cached").must_equal nil
      check.an_object
      check.instance_variable_defined?("@an_object_cached").must_equal true
      check.instance_variable_get("@an_object_cached").must_be_instance_of CompatibleOpenStruct
    end

    describe "providing a class to handle a json object" do

      it "we correctly have an instace of our object handler" do
        subject.json_object_accessor :an_object, class: object_handler_class
        subject.new(json).an_object.must_be_instance_of object_handler_class
      end

      it "the object handler contains the correct values " do
        subject.json_object_accessor :an_object, class: object_handler_class
        object_handler_class.json_value_accessor :an_integer
        subject.new(json).an_object.id.must_equal 1
      end

      it "the object handler has a json_value_accessor set that has access to the object and its parent via proc" do
        subject.json_value_accessor :name
        object_handler_class.json_value_accessor :parents_name, proc: Proc.new {|json_object, value| json_object.json_parent.name}
        subject.json_object_accessor :an_object, class: object_handler_class
        subject.new(json).an_object.parents_name.must_equal "record one"

        #also confirm the parent is correct
        result = subject.new(json)
        result.an_object.json_parent.must_equal result
      end
    end

    describe "not supplying a specific object handler" do

      it "assigns the values to an OpenStruct object by default" do
        subject.json_object_accessor :an_object
        subject.new(json).an_object.must_be_instance_of CompatibleOpenStruct
      end

      it "also has access to the parent" do
        subject.json_object_accessor :an_object
        result = subject.new(json)
        result.an_object.json_parent.must_equal result
      end
    end

    describe "an object handler given a nil (non-existing json object)" do

      it "simply returns nil" do
        subject.json_object_accessor :dosent_exist, class: object_handler_class
        subject.new(json).dosent_exist.must_be_nil
      end

    end

    describe "with arrays" do
      let(:json) do
        JSON.parse(<<-EOS
          {"objects":[
            {"id":1, "name":"object one"},
            {"id":2, "name":"object two"},
            {"id":3, "name":"object three"}
            ]
          }
        EOS
        )
      end

      describe "not supplying object class handlers" do

        it "when theres an array of objects we will get back an array" do

          subject.json_object_accessor :objects
          subject.new(json).objects.must_be_instance_of Array
        end

        it "the array will contain OpenStruct objects" do

          subject.json_object_accessor :objects
          subject.new(json).objects[0].must_be_instance_of CompatibleOpenStruct

        end

        it "when the json array is empty the return value will be as well" do
          subject.json_object_accessor :objects
          subject.new(JSON.parse('{"objects":[]}')).objects.must_be_empty
        end
      end

      describe "when using object handler classes" do

        it "providing a custom class for our objects works" do
          subject.json_object_accessor :objects, class: object_handler_class
          subject.new(json).objects.must_be_instance_of Array
        end

        it "the array will contain our supplied object handlers" do
          subject.json_object_accessor :objects, class: object_handler_class
          subject.new(json).objects[0].must_be_instance_of object_handler_class
        end

        it "when the json array is empty the return value will be as well" do
          subject.json_object_accessor :objects, class: object_handler_class
          subject.new(JSON.parse('{"objects":[]}')).objects.must_be_empty object_handler_class
        end

        it "if we rename the accessor name it will be used instead of the attribute name" do
          subject.json_object_accessor :objects, name: 'cool_objects', class: object_handler_class
          subject.new(json).methods.must_include :cool_objects
          subject.new(json).cool_objects.first.id.must_equal 1
        end

      end
    end

    describe "with arrays that have null entries" do
      let(:json) do
        JSON.parse(<<-EOS
          {"objects":[
            null,
            {"id":2, "name":"object three"},
            {"id":3, "name":"object three"}
            ]
          }
        EOS
        )
      end

      describe "not supplying object class handlers" do

        it "OpenStruct handles a nil initializer" do
          subject.json_object_accessor :objects
          subject.new(json).objects.must_be_instance_of Array
          subject.new(json).objects.first.must_be_instance_of CompatibleOpenStruct
        end
      end

      describe "supplying an object handler class" do
        it "OpenStruct handles a nil initializer" do
          subject.json_object_accessor :objects, class: object_handler_class
          subject.new(json).objects.must_be_instance_of Array
          subject.new(json).objects.first.must_be_instance_of object_handler_class
          subject.new(json).objects.first.id.must_equal nil
        end
      end
    end
  end
end
