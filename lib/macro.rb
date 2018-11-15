require 'erb'

class MacroProcessor

  class ERBExpander
    def initialize(text, hash)
      @text = text
      @hash = hash
    end
    
    def result
      ERB.new(@text).result(binding)
    end

    def unless_last_element(str)
      if @hash[:last_element]
        ""
      else
        str
      end
    end
    
    def method_missing(sym)
      if @hash[sym]
         @hash[sym]
      else
        raise "Symbol #{sym} not found in hash #{@hash}"
      end
    end
  end

  class Macro
    attr_reader :name, :lines
    def initialize(name, indent)
      @name = name
      @indent = indent
      @lines = []
    end

    def add_line(line)
      @lines << line
    end

    def expand(data, last_element)
      begin
        erbed = ERBExpander.new(@lines.join("\n"), data.merge({last_element: last_element})).result
        erbed.split(/\n/).reject{|line| line.strip.empty?}.map{|line| @indent + line}
      rescue Exception => e
        raise "In macro #{@name} #{e}"
      end
    end

    def dup_with_data(data)
      m = Macro.new(@name, @indent)
      data.split(/\n/).each do |line|
        m.add_line(line)
      end
      m
    end
  end

=begin
  class EvaluationContext
    def initialize(macro_processor)
      @macro_processor = macro_processor
    end

    def evaluate(lines)
      instance_eval(lines.join("\n"))
    end

    def evaluate_and_return_lines(lines)
      @new_lines = []
      instance_eval(lines.join("\n"))
      @new_lines
    end

    def expand_macro(macro_name, *params)
      macro = @macro_processor.macros[macro_name.to_s]
      raise "macro not found #{macro_name}" unless macro

      @new_lines << macro.translate_lines(params)
    end
  end
=end
  attr_reader :macros

  def initialize(macros: {})
    @macros = macros
  end

  def read_definitions(text)
    macroize(text, read_definitions_only: true)
  end

  def macroize(text, input_data: {}, verbose: false, copy_def_data: false, copy_expand_data: true, read_definitions_only: false)
    @state = :before
    @data = input_data
    @output_lines = []
    @data_lines = []
    @expand_stack = []
    @current_macro = nil
    @verbose = verbose
    @copy_def_data = copy_def_data
    @copy_expand_data = copy_expand_data
    #evaluation_context = EvaluationContext.new(self)

    line_number = 1
    text.split(/\n/).each do |line|
      if @verbose
        puts ("(%-3d %-13s): %s" % [line_number, @state, line])
      end

      case @state
      when :before
        if m = /^(\s*)\/\/ macro-def\(:(\w+)\)/.match(line)
          indent = m[1]
          macro_name = m[2]
          puts "STATUS: defining macro #{macro_name}" if @verbose
          @current_macro = Macro.new(macro_name, indent)
          @state = :in_macro_def
          @output_lines << line if @copy_def_data
        elsif (m = /macro-expand\(:(\w+)\)/.match(line)) && !read_definitions_only
          start_expand(m[1], line)
        elsif m = /macro-data/.match(line)
          @data_lines = []
          @state = :in_data_def
          @output_lines << line
        else
          @output_lines << line
        end

      when :in_macro_def
        if m = /macro-def-end\(:(\w+)\)/.match(line)
          @macros[@current_macro.name] = @current_macro
          @state = :before
        else
          if m = /^(\s*)\/\/ (.*)$/.match(line)
            @current_macro.add_line(m[2])
          end
        end
        @output_lines << line if @copy_def_data

      when :in_data_def
        if m = /macro-data-end/.match(line)
          evaluation_context.evaluate(@data_lines)
          @state = :before
        else
          if m = /^\/\/(.*)$/.match(line)
            @data_lines << m[1]
          end
        end
        @output_lines << line

      when :in_expand_def
        if (m = /macro-expand-end\(:(\w+)\)/.match(line)) && !read_definitions_only
          #evaluation_context.evaluate_and_return_lines(@expand_lines).each do |eline|
          #  @output_lines << eline
          #end
          macro_name = m[1].to_sym
          macro_data = @data[macro_name]
          raise "data not associated with macro #{macro_name}" if macro_data.nil?

          macro_data = macro_data.is_a?(Array) ? macro_data : [macro_data]
          macro_data.each_with_index do |mdata, index|
            output = self.class.new(macros: @macros).macroize(@current_macro.lines.join("\n"),
                                    input_data: @data,
                                    verbose: @verbose,
                                    copy_expand_data: false,
                                    copy_def_data: @copy_def_data)
            #puts "output = #{output}"
            @current_macro.dup_with_data(output).expand(mdata, index == macro_data.size - 1).each do |eline|
              @output_lines << eline
            end
          end
          @output_lines << line if @copy_expand_data

          @expand_stack.pop

          if @expand_stack.empty?
            @state = :before
          else
            @current_macro = @expand_stack.last
          end
        else
          if m = /^(\s*)\/\/(.*)$/.match(line)
            after_comment = m[2]
            if (m = /macro-expand\(:(\w+)\)/.match(line)) && !read_definitions_only
              start_expand(m[1], line)
            else
              @output_lines << line
            end
          else
            # don't add to output
          end
        end
      end
      line_number += 1
    end
    
    @output_lines.join("\n") + "\n"
  end

  def start_expand(macro_name, line)
    @current_macro = @macros[macro_name]
    raise "macro #{macro_name} not defined, macros = #{@macros}" unless @current_macro
    @expand_stack.push(@current_macro)
    @state = :in_expand_def
    puts "STATUS: expanding macro #{macro_name}" if @verbose
    @output_lines << line if @copy_expand_data
  end
end

text = <<EOT
some text
// macro-data
// @data = [[1,2], [3,4]]
// macro-data-end
// macro-def(:hello, a, b)
// expand line ${a}
// expand line ${b}
// macro-def-end(:hello)
after text
    // macro-expand(:hello)
    // @data.each do |a,b|
    //   expand_macro(:hello, a, b)
    // end
    expand line 1
    expand line 2
    // macro-expand-end(:hello)
end text
EOT

#puts "---------------------------"
#puts MacroProcessor.new.macroize(text)
#puts "---------------------------"

