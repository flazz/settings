require 'set'

module Settings

  def self.helper_methods_module setting
    mod = Module.new
    
    mod.send(:define_method, name) do
      get_setting name
    end
      
    mod.send(:define_method, "#{name}=") do |value|
      set_setting name, value
    end
  end
  
  def self.define klass, setting
    klass.extend ClassMethods
    klass.include InstanceMethods
    klass.include helper_methods_module(setting)
    
    klass.settings << setting
  end
  
  module ClassMethods
    def settings
      @settings ||= Set.new
    end
  end
  
  module InstanceMethods
    def settings
      @settings ||= self.class.settings.dup
    end
    
    def handles_setting? name
      @settings.include name
    end
    
    def setting_set? name
      instance_variable_defined? "@#{name}"
    end
    
    def get_setting name
      instance_variable_get "@#{name}"
    end
    
    def set_setting name, value
      instance_variable_set "@#{name}", value
    end
  end
  
end

describe "An object that has settings" do
  let(:klass) { Class.new }
  let(:object) { klass.new }
  
  before
    Settings.define klass, :foo
    Settings.define klass, :bar
  end
  
  describe "asked for a list of settings it handles" do
    subject { object.settings }
    
    it "gives me a list of settings" do
      should include :foo
      should include :bar
    end
  end
  
  describe "asked if it handles a setting" do
    context "when it does handle the setting" do
      subject { object.handles_setting? :foo }
      it { should be_true }
    end
    
    context "when it does *NOT* handle the setting" do
      subject { object.handles_setting? :other }
      it { should be_false }
    end
  end
  
  describe "provided a value for the setting" do
    subject { lambda { object.set_setting :foo, "Foo" } }
    
    it "stores the value in an instance variable of the same name" do
      object.should_receive(:instance_variable_set).with("@foo", "Foo")
      subject.call
    end
  end
  
  describe "asked for the setting value" do
    subject { lambda { object.get_setting :foo } }
    
    it "tells me the value of the instance variable of the same name" do
      object.should_receive(:instance_variable_get).with("@foo").and_return("Foo")
      subject.call.should == "Foo"
    end
  end
  
  describe "asked if a setting has been provided a value" do
    subject { object.setting_provided? :foo }
    
    context "when a value has been provided" do
      before { object.set_setting :foo, "Foo" }
      it { should be_true }
    end
    
    context "when a value has *NOT* been provided" do
      it { should be_false }
    end
  end
end