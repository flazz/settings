require 'set'

module Settings
  def self.helper_methods_module name
    mod = Module.new
    mod.send(:define_method, name) { get_setting(name) }
    mod.send(:define_method, "#{name}=") { |value| set_setting(name, value) }
    mod
  end

  def self.define klass, name
    klass.extend ClassMethods 
    klass.send :include, InstanceMethods
    klass.send :include, helper_methods_module(name)

    klass.settings << name
  end
  
  module DSL
    def self.included base
      base.extend ClassMethods
    end

    module ClassMethods
      def define_settings *names
        names.each { |name| define_setting(name) }
      end

      def define_setting name
        Settings.define self, name
      end
    end
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

    def settings_provided
      @settings_provided ||= []
    end

    def validate_setting_exists! name
      message = "Unknown setting: #{name}"
      raise Settings::UnknownSettingError, message unless handles_setting?(name)
    end
    
    def setting_exists? name
      settings.include?(name)
    end
    alias :handles_setting? :setting_exists?
    
    def setting_provided? name
      validate_setting_exists! name
      settings_provided.include? name
    end
    
    def get_setting name
      validate_setting_exists! name
      instance_variable_get "@#{name}"
    end
    
    def set_setting name, value
      validate_setting_exists! name
      instance_variable_set "@#{name}", value
      settings_provided << name
    end
  end
  
end

describe "A class that has settings" do
  let(:klass) { Class.new }
  let(:object) { klass.new }
  
  before do
    Settings.define klass, :foo
    Settings.define klass, :bar
  end
  
  context "helper methods" do
    
    describe "setter method" do
      subject { object.method "foo=" }

      it "sets the value of the setting" do
        object.should_receive(:set_setting).with(:foo, "Foo")
        subject.call "Foo"
      end
    end

    describe "getter method" do
      subject { object.method "foo" }

      it "gets the value of the setting" do
        object.should_receive(:get_setting).with(:foo).and_return("Foo")
        subject.call.should == "Foo"
      end
    end
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

describe "The DSL for settings" do
  let(:klass) { Class.new }

  describe "defining a setting" do
    subject do
      lambda do |name|
        klass.class_eval do
          include Settings::DSL
          define_setting name
        end
      end
    end

    it "defines a setting for that class" do
      Settings.should_receive(:define).with(klass, :foo)
      subject.call :foo
    end
  end

  describe "defining multiple settings at once" do
    subject do
      lambda do |*names|
        klass.class_eval do
          include Settings::DSL
          define_settings *names
        end
      end
    end

    it "defines those settings for that class" do
      Settings.should_receive(:define).with(klass, :foo)
      Settings.should_receive(:define).with(klass, :bar)

      subject.call :foo, :bar
    end
  end
end
