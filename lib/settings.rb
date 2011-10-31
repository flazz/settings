module Settings

  module ClassMethods

    def setting(name)
      settings << name
      attr_writer name unless method_defined? :"#{name}="
    end

    def settings
      @settings ||= []
    end

  end

  def self.included(mod)
    mod.extend ClassMethods
  end

  def settings
    @settings ||= initial_settings
  end

  def initial_settings
    self.class.settings.dup
  end

  def setting?(name)
    settings.include? name
  end

  def set(name, value)
    send :"#{name}=", value
  end

end
