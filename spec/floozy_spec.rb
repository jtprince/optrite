require 'spec_helper'

describe Floozy do
  describe 'simple cases' do
    it 'runs the rdoc example' do

      require 'floozy'

      parser = Floozy.new do |p|
        p.version "fancy script 0.0 alpha" # sets up --version && exit option
        p.usage "file1 ..."
        p.text "output: file1.baconated"
        p.text
        p.text "options:"
        p.opt :verbose, "enable verbose output"
        p.opt :severity, "set severity", :default => 4, :value_in_set => [4,5,6,7,8]
        p.opt :mutation, "set mutation", :default => "MightyMutation", :value_matches => /Mutation/
          p.opt :plus_selection, "use plus-selection if set", :default => true
        p.opt :selection, "selection used", :default => "BestSelection", :short => "l"
        p.opt :chance, "set mutation chance", :type => :float, :value_satisfies => lambda {|x| x >= 0.0 && x <= 1.0}
      end

      options = parser.parse!  # returns a hash

      if ARGV.size == 0
        puts parser
        exit
      end
    end


    end
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
      options.should == {:severity=>4, :verbose=>nil, :mutation=>"MightyMutation", :plus_selection=>true, :selection=>"BestSelection", :chance=>0.8}
    end

    it 'allows all defaults to be set at once, not minding if there are extra keys' do
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

    it 'can set the option type without giving a default' do
      fl = Floozy.new do |p|
        p.opt :intopt1, "", :type => Integer
        p.opt :intopt2, "", :type => :int
        p.opt :intopt2n, "", :type => :int
        p.opt :stringopt1, "", :type => String
        p.opt :stringopt2, "", :type => :string
        p.opt :stringopt2n, "", :type => :string
        p.opt :boolopt0, ""  # or boolean (although type is assumed boolean if none given
        p.opt :boolopt1, "", :type => :bool  # or boolean (although type is assumed boolean if none given
        p.opt :boolopt2, "", :type => TrueClass
        p.opt :boolopt2n, "", :type => TrueClass
      end
      options = fl.process!(%w(--intopt1 2 --intopt2 3 --stringopt1 3 --stringopt2 happy --boolopt0 --boolopt1 --no-boolopt2) )
      options.should == {:intopt1=>2, :intopt2=>3, :intopt2n=>nil, :stringopt1=>"3", :stringopt2=>"happy", :stringopt2n=>nil, :boolopt0=>true, :boolopt1=>true, :boolopt2=>false, :boolopt2n=>nil}

    end

    it 'can auto-generate a usage line' do
      fl = Floozy.new do |p|
        p.usage
        p.opt :boolopt2, "", :type => TrueClass
      end
      fl.process! []  # <-- I shouldn't have to process things to look at the complete help message!
      fl.to_s.should =~ /^usage: rspec\n/

      fl = Floozy.new do |p|
        p.usage "[OPTIONS] <file1> <file2>"
        p.opt :wildness
      end
      fl.process!([])
      fl.to_s.should =~ /^usage: rspec \[OPTIONS\] <file1> <file2>/
    end

    it 'allows the addition of text lines (for things like option grouping)' do
      fl = Floozy.new do |p|
        p.banner = "This is a fancy script, for usage see below"
        p.text "[I just like my space here]"
        p.version = "fancy script 0.0 alpha"
        p.text  # can be given no args
        p.text "WEIRD OPTIONS: "
        p.opt :severity, "set severity", :default => 4, :value_in_set => [4,5,6,7,8]
        p.opt :verbose, "enable verbose output"
        p.text ""
        p.separator "EVEN STRANGER OPTIONS:"  # also can call separator
        p.opt :plus_selection, "use plus-selection if set", :default => true
        p.opt :selection, "selection used", :default => "BestSelection", :short => "l"
      end
      options = fl.process!([])
      options.should == {:severity=>4, :verbose=>nil, :plus_selection=>true, :selection=>"BestSelection"}
      fl.to_s.should =~ /This is a fancy/
      fl.to_s.should =~ /WEIRD OPTIONS: /
      fl.to_s.should =~ /EVEN STRANGER OPTIONS:/
    end

    it 'can cast and validate arguments' do

    end

    it 'can do subcommands' do

    end

    it 'formats to fit terminal size, even on windows'
    it 'can cast items handed in inside an array'

    it 'is contained entirely within one file' do
      Dir[File.dirname(__FILE__) + "/../lib/*"].size.should == 1
    end


  end

end
