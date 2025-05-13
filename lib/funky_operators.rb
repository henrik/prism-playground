require "prism"
require "require-hooks/setup"

class FunkyOperators
  class Visitor < Prism::Visitor
    attr_reader :locations

    def initialize
      @locations = []
    end

    def visit_call_node(node)
      if node.name == :+
        loc = node.message_loc
        @locations << [ loc.start_offset, loc.length ]
      end

      super
    end
  end

  def self.init
    RequireHooks.source_transform(
      patterns: [ "#{Dir.pwd}/*.rb" ],
      exclude_patterns: [ "#{Dir.pwd}/lib/*" ],
    ) do |path, source|
      pretty_path = path.sub(Dir.pwd, ".")
      puts "#{name} processing #{source ? "source originally from #{pretty_path}" : pretty_path}…" if $DETAILS

      source ||= File.read(path)
      process(source)
    end
  end

  def self.process(source)
    program_node = Prism.parse(source).value

    visitor = Visitor.new
    visitor.visit(program_node)

    new_source = source.dup

    # In reverse so we wouldn't shift positions if we changed length (though we don't, currently).
    visitor.locations.reverse_each do |offset, length|
      new_source[offset, length] = "-"
    end

    if $DETAILS
      puts "=" * 40
      puts new_source
      puts "=" * 40
      puts
    end

    new_source
  end
end

FunkyOperators.init
