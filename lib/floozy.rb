
require 'optparse'
require 'set'

# copied *liberally* from micro-optparse.  See LICENSE.txt for more detailed.

class Floozy

  # typically nil or false
  DEFAULT_BLANK = nil

  Option = Struct.new(:name, :desc, :settings)

  attr_writer :version
  # a hash of symbol => value that can be used to fill the defaults 
  attr_writer :defaults
  # the underlying OptionParser object
  attr_accessor :option_parser
  # each of the Floozy::Options given
  attr_accessor :options

  # the name of the command (or subcommand)
  attr_accessor :name
  attr_accessor :desc

  # will only validate arguments the user provided, which avoids problems
  # dealing with arguments without a default or invalid defaults.
  attr_accessor :only_validate_given

  # an array of little option parsers
  attr_accessor :commands

  # sets the banner attribute with a usage line using the script name
  # File.basename($0).  Returns the current banner attribute
  def usage(args_and_such=nil)
    _banner = "usage: #{File.basename($0)}"
    (_banner << ' ' << args_and_such) if args_and_such
    @option_parser.banner = _banner
  end

  def command(name, desc, &block)
    @commands << Floozy.new(name, desc, &block)
  end

  def banner=(arg)
    @option_parser.banner = arg
  end

  # allows getting or setting based on whether an argument was provided
  def banner(arg=nil)
    arg.nil? ? @option_parser.banner : (@option_parser.banner = arg)
  end

  # allows getting or setting based on whether an argument was provided.  This
  # should be done *before* calls to *option* or it will wipe out individually
  # set options.
  def defaults(arg=nil)
    arg.nil? ? @defaults : (@defaults = arg)
  end

  # allows getting or setting based on whether an argument was provided
  def version(arg=nil)
    arg.nil? ? @version : (@version = arg)
  end

  def initialize(name=$0, desc="", settings={:only_validate_given=>true}, &block)
    @desc = desc
    @name = name
    @commands = []
    @options = []
    @result = {}
    @given = Set.new  # symbols of arguments given
    @only_validate_given = settings[:only_validate_given]
    @used_short = []
    @defaults = {}
    @option_parser = OptionParser.new
    block.call(self) if block
    @dispatch_block = nil
  end

  # returns self
  def option(name, desc="", settings = {})
    fopt = Floozy::Option.new(name, desc, settings)
    @options << fopt
    short = (fopt.settings[:short] || short_from(fopt.name))
    @used_short << short
    default = 
      if fopt.settings.key?(:default)
        fopt.settings[:default]
      elsif @defaults.key?(fopt.name)
        @defaults[fopt.name]
      else
        DEFAULT_BLANK
      end
    @defaults[fopt.name] = default
    klass = 
      if fopt.settings[:type]
        type_to_class(fopt.settings[:type]) 
      else
        Fixnum.===(default) ? Integer : default.class
      end

    on_opt = lambda {|v| @given.add(fopt.name) && @result[fopt.name] = v }
    if [TrueClass, FalseClass, NilClass].include?(klass) # boolean switch
      @option_parser.on("-" << short, name_to_longopt(fopt.name, true), fopt.desc, &on_opt)
    else # argument with parameter
      @option_parser.on("-" << short, name_to_longopt(fopt.name) << " " << default.to_s, klass, fopt.desc, &on_opt)
    end
    self
  end
  alias_method :opt, :option

  def text(arg="")
    @option_parser.separator(arg)
  end
  alias_method :separator, :text

  def short_from(name)
    name.to_s.each_char.find do |char|
      !@used_short.include?(char) || char != '_'
    end
  end

  def name_to_longopt(name, boolean=false)
    (boolean ? "--[no-]" : "--") << name.to_s.gsub("_", "-")
  end

  def type_to_class(arg)
    return arg if arg.is_a?(Class)
    case arg.to_s
    when /bool/
      FalseClass
    when /int/
      Integer
    when /float/
      Float
    when /string/
      String
    else
      raise "invalid type: #{arg}"
    end
  end

  # recognizes :value_in_set, :value_matches, and :value_satisfies
  def validate(option_value_pairs)
    option_value_pairs.each do |key, value|
      opt = @options.find{|option| option.name == key }
      key = name_to_longopt(key)
      unless opt.settings[:value_in_set].nil? || opt.settings[:value_in_set].include?(value)
        puts "Parameter for #{key} must be in [" << opt.settings[value_in_set].join(", ") << "]" ; exit(1)
      end
      unless opt.settings[:value_matches].nil? || opt.settings[:value_matches] =~ value
        puts "Parameter for #{key} must match /" << opt.settings[:value_matches].source << "/" ; exit(1)
      end
      unless opt.settings[:value_satisfies].nil? || opt.settings[:value_satisfies].call(value)
        puts "Parameter for #{key} must satisfy given conditions (see description)" ; exit(1)
      end
    end
  end

  # yields args and options
  def dispatch(&block)
    @dispatch_block = block
  end

  def to_s
    st = @option_parser.to_s
    if @commands.size > 0
      st << "\ncommands: \n"
      @commands.each do |command|
        # need to space properly
        st << "    #{command.name}   #{command.desc}\n"
      end
    end
    st
  end
  alias_method :educate, :to_s
  alias_method :help, :to_s

  def process!(args = ARGV)
    if @commands.size > 0
      cmd_names_as_strings = @commands.map {|cmd| cmd.name.to_s }
      index = args.index {|arg| cmd_names_as_strings.include?(arg) } || args.size
      my_args = args[0...index]
      cmd_args = args[(index+1)...args.size]
      puts "MY ARGS / cmd args:"
      p my_args
      p cmd_args
      command[index].parse!(cmd_args)
    end
    @result = @defaults.clone
    @result.delete_if {|key,value| @options.none? {|fopt| fopt.name == key } }
    op = @option_parser

    op.banner = @banner unless @banner.nil?
    op.on_tail("-h", "--help", "Show this message") {puts op ; exit}
    short = @used_short.include?("v") ? "-V" : "-v"
    op.on_tail(short, "--version", "Print version") {puts @version ; exit} unless @version.nil?

    begin
      @option_parser.parse!(args)
    rescue OptionParser::ParseError => e
      puts e.message ; exit(1)
    end

    given_pairs = @result.select {|k,v| @given.include?(k) }
    validate(given_pairs) if self.respond_to?(:validate)

    # dispatch and return the result if given, otherwise
    if @dispatch_block
      # need to think about checking arity, etc. and handing
      @dispatch_block.call(args, @result)
    else
      @result
    end
  end
  #alias_method :process!, :parse!
end
