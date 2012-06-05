require 'spec_helper'

describe Floozy do
  it 'acts like micro-optparse for simple cases' do

    fl = Floozy.new do |p|
      p.banner = "This is a fancy script, for usage see below"
      p.version = "fancy script 0.0 alpha"
      p.opt :severity, "set severity", :default => 4, :value_in_set => [4,5,6,7,8]
      p.opt :verbose, "enable verbose output"
      p.opt :mutation, "set mutation", :default => "MightyMutation", :value_matches => /Mutation/
      p.opt :plus_selection, "use plus-selection if set", :default => true
      p.opt :selection, "selection used", :default => "BestSelection", :short => "l"
      p.opt :chance, "set mutation chance", :default => 0.8, :value_satisfies => lambda {|x| x >= 0.0 && x <= 1.0}
    end
    options = fl.process!([])
    options.should == 
  end

  it 'allows all defaults to be set at once' do
  end

  it 'can do subcommands' do
  end

  it 'allows option grouping' do
  end

  it 'is contained in one file' do
  end

  it 'formats to fit terminal size, even on windows' do
  end

end
