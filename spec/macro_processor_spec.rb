require 'spec_helper'
require 'macro'

describe MacroProcessor do
  it "starts with empty macros hash" do
    expect(subject.macros).to eq({})
  end

  it "passes unmacroized data through" do
    expect(subject.macroize("line 1\nline 2\n", copy_def_data: true)).to eq("line 1\nline 2\n")
  end

  it "passes through macro definitions" do
    input = <<-EOT
      line 1
      // rubymacro-def(:test)
      // rubymacro-def-end(:test)
      line 2
      EOT
    expected_output = <<-EOT
      line 1
      // rubymacro-def(:test)
      // rubymacro-def-end(:test)
      line 2
      EOT
    expect(subject.macroize(input, copy_def_data: true)).to eq(expected_output)
  end

  it "expands a macro" do
    input = <<-EOT
      line 1
      // macro-def(:test)
      // <%= test_var %>
      // macro-def-end(:test)
      line 2
      // macro-expand(:test)
      // macro-expand-end(:test)
      EOT
    expected_output = <<-EOT
      line 1
      // macro-def(:test)
      // <%= test_var %>
      // macro-def-end(:test)
      line 2
      // macro-expand(:test)
      some text
      // macro-expand-end(:test)
      EOT
    expect(subject.macroize(input, input_data: {test: {test_var: "some text"}}, copy_def_data: true)).to eq(expected_output)
  end

  it "expands a macro with embedded if" do
    input = <<-EOT
      line 1
      // macro-def(:test)
      // <% if test_var == "hello" %>
      // <%= test_var %>A
      // <% else %>
      // <%= test_var %>B
      // <% end %>
      // macro-def-end(:test)
      line 2
      // macro-expand(:test)
      // macro-expand-end(:test)
      EOT
    expected_output = <<-EOT
      line 1
      // macro-def(:test)
      // <% if test_var == "hello" %>
      // <%= test_var %>A
      // <% else %>
      // <%= test_var %>B
      // <% end %>
      // macro-def-end(:test)
      line 2
      // macro-expand(:test)
      some textB
      // macro-expand-end(:test)
      EOT
    expect(subject.macroize(input, input_data: {test: {test_var: "some text"}}, copy_def_data: true)).to eq(expected_output)
  end

  it "expands a macro with an array of data" do
    input = <<-EOT
      line 1
      // macro-def(:test)
      // <%= test_var %>
      // macro-def-end(:test)
      line 2
      // macro-expand(:test)
      // macro-expand-end(:test)
      EOT
    expected_output = <<-EOT
      line 1
      // macro-def(:test)
      // <%= test_var %>
      // macro-def-end(:test)
      line 2
      // macro-expand(:test)
      some text
      some text2
      // macro-expand-end(:test)
      EOT
    expect(subject.macroize(input, input_data: {test: [{test_var: "some text"}, {test_var: "some text2"}]}, copy_def_data: true)).to eq(expected_output)
  end

  it "expands a nested macro" do
    input = <<-EOT
      line 1
      // macro-def(:test2)
      // <%= test2_var %>
      // macro-def-end(:test2)
      // macro-def(:test)
      // <%= test_var %>
      // macro-expand(:test2)
      // macro-expand-end(:test2)
      // macro-def-end(:test)
      line 2
      // macro-expand(:test)
      // macro-expand-end(:test)
      EOT
    expected_output = <<-EOT
      line 1
      // macro-def(:test2)
      // <%= test2_var %>
      // macro-def-end(:test2)
      // macro-def(:test)
      // <%= test_var %>
      // macro-expand(:test2)
      // macro-expand-end(:test2)
      // macro-def-end(:test)
      line 2
      // macro-expand(:test)
      some text
      some other text
      // macro-expand-end(:test)
      EOT
    expect(subject.macroize(input, input_data: {test: {test_var: "some text"}, test2: {test2_var: "some other text"}}, copy_def_data: true, verbose: true)).to eq(expected_output)

  end
end
