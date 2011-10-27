require 'pp'
require 'settings'

class Thing
  include Settings
  attr_writer :p

  # declares :p something to be set
  # does not define Thing#p= it already exists
  setting :p

  # declares :q something to be set
  # Thing#q=, is this right?
  # least surprise says no
  # metaprogramming convention says yes because we don't want many declarations that contain :p
  # satisfying the stimulation for DRY could lead to defining Thing#q too.
  # Thing#q has nothing to do with setting something at all.
  setting :q
end

thing = Thing.new
thing.setting? :p # => true
thing.setting? :q # => true
thing.settings # => [:p, :q]

thing.p = 'some value'
thing.q = 'some value'
