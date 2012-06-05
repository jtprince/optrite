require 'spec_helper'

describe Floozy do
  describe 'simple cases' do
    it 'acts like micro-optparse' do
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
      options.should == {:severity=>4, :verbose=>false, :mutation=>"MightyMutation", :plus_selection=>true, :selection=>"BestSelection", :chance=>0.8}
    end

    it 'allows all defaults to be set at once, not minding if they are over specified' do
      defaults = {
        :severity => 4, 
        :selection => 'BestSelection', 
        :chance => 0.8
      }
      fl = Floozy.new do |p|
        p.opt :severity, "set severity", :value_in_set => [4,5,6,7,8]
        p.opt :selection, "selection used", :short => "l"
        p.defaults = defaults
      end
      options = fl.process!([])
      options.should == {:severity=>4, :selection=>"BestSelection"}
    end

    it 'can set type without giving a default' do
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

end
