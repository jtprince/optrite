
require 'optparse'

# copied *liberally* from micro-optparse.  See LICENSE.txt for more detailed.

class Floozy

  # typically nil or false
  DEFAULT_BLANK = nil

  Option = Struct.new(:name, :desc, :settings)

  attr_writer :banner, :version
  # a hash of symbol => value that can be used to fill the defaults 
  attr_writer :defaults
  # the underlying OptionParser object
  attr_accessor :option_parser

  # sets the banner attribute with a usage line using the script name
  # File.basename($0).  Returns the current banner attribute
  def usage(args_and_such=nil)
    @banner = "usage: #{File.basename($0)}"
    (@banner << ' ' << args_and_such) if args_and_such
    @banner
  end

  # allows getting or setting based on whether an argument was provided
  def banner(arg=nil)
    arg.nil? ? @banner : (@banner = arg)
  end

  # allows getting or setting based on whether an argument was provided
  def defaults(arg=nil)
    arg.nil? ? @defaults : (@defaults = arg)
  end

  # allows getting or setting based on whether an argument was provided
  def version(arg=nil)
    arg.nil? ? @version : (@version = arg)
  end

  def initialize(&block)
    @opts_etc = []
    @used_short = []
    @defaults = {}
    @default_values = nil
    @option_parser = OptionParser.new
    block.call(self) if block
  end

  # returns only the options out of the opts_etc things
  def options
    @opts_etc.select {|obj| obj.is_a?(Floozy::Option) }
  end

  def option(name, desc="", settings = {})
    @opts_etc << Floozy::Option.new(name, desc, settings)
  end
  alias_method :opt, :option

  def text(arg="")
    @opts_etc << arg
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

  def validate(opt_hash)
    opt_hash.each_pair do |key, value|
      opt = options.find{|option| option.name == key }
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

  def to_s
    @option_parser.to_s
  end
  alias_method :educate, :to_s
  alias_method :help, :to_s

  def process!(args = ARGV)
    @result = (@default_values || {}).clone # reset or new
    op = @option_parser
    @opts_etc.each do |thing|
      if thing.is_a?(String)
        op.separator(thing) 
      else
        option = thing
        short = (option.settings[:short] || short_from(option.name))
        @used_short << short
        default = option.settings[:default] || @defaults[option.name] || DEFAULT_BLANK # set default
        @result[option.name] = default         
        klass = 
          if option.settings[:type]
            type_to_class(option.settings[:type]) 
          else
            Fixnum.===(default) ? Integer : default.class
          end

        if [TrueClass, FalseClass, NilClass].include?(klass) # boolean switch
          op.on("-" << short, name_to_longopt(option.name, true), option.desc) {|v| @result[option.name] = v}
        else # argument with parameter
          op.on("-" << short, name_to_longopt(option.name) << " " << default.to_s, klass, option.desc) {|x| @result[option.name] = x}
        end
      end
    end

    op.banner = @banner unless @banner.nil?
    op.on_tail("-h", "--help", "Show this message") {puts op ; exit}
    short = @used_short.include?("v") ? "-V" : "-v"
    op.on_tail(short, "--version", "Print version") {puts @version ; exit} unless @version.nil?
    @default_values = @result.clone # save default values to reset @result in subsequent calls

    begin
      @option_parser.parse!(args)
    rescue OptionParser::ParseError => e
      puts e.message ; exit(1)
    end

    validate(@result) if self.respond_to?(:validate)
    @result
  end

end
