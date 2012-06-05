
# copied *liberally* from micro-optparse.  See LICENSE.txt for more detailed.

class Floozy

  Option = Struct.new(:name, :desc, :settings) 

  attr_accessor :banner, :version
  # a hash of symbol => value that can be used to fill the defaults 
  attr_accessor :defaults
  def initialize(&block)
    @options = []
    @used_short = []
    @defaults = {}
    @default_values = nil
    block.call(self) if block
  end

  def option(name, desc, settings = {})
    @options << Option.new(name, desc, settings)
  end
  alias_method :opt, :option

  def short_from(name)
    name.to_s.each_char.find do |char|
      !@used_short.include?(char) || char != '_'
    end
  end

  def validate(options)
    options.each_pair do |key, value|
      opt = @options.find_all{ |option| option.name == key }.first
      key = "--" << key.to_s.gsub("_", "-")
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

  def process!(args = ARGV)
    @result = (@default_values || {}).clone # reset or new
    @optionparser ||= OptionParser.new do |op| # prepare only once
      @options.each do |option|
        short = (option.settings[:short] || short_from(option.name))
        @used_short << short
        default = option.settings[:default] || @defaults[option.name] || false # set default
        @result[option.name] = default         
        klass = ( Fixnum===default ? Integer : default.class )

        if [TrueClass, FalseClass, NilClass].include?(klass) # boolean switch
          op.on("-" << short, "--[no-]" << option.name.to_s.gsub("_", "-"), option.desc) {|v| @result[option.name] = v}
        else # argument with parameter
          op.on("-" << short, "--" << option.name.to_s.gsub("_", "-") << " " << default.to_s, klass, option.desc) {|x| @result[option.name] = x}
        end
      end

      op.banner = @banner unless @banner.nil?
      op.on_tail("-h", "--help", "Show this message") {puts op ; exit}
      short = @used_short.include?("v") ? "-V" : "-v"
      op.on_tail(short, "--version", "Print version") {puts @version ; exit} unless @version.nil?
      @default_values = @result.clone # save default values to reset @result in subsequent calls
    end

    begin
      @optionparser.parse!(args)
    rescue OptionParser::ParseError => e
      puts e.message ; exit(1)
    end

    validate(@result) if self.respond_to?("validate")
    @result
  end

end
