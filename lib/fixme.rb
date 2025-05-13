require "prism"
require "require-hooks/setup"

class Fixme
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
    new_source = source.dup

    Prism.parse_comments(source).reverse_each do |comment|
      loc = comment.location
      old_comment = source[loc.start_offset, loc.length]

      if old_comment.match(/\A#\s*FIXME (\d{4}-\d\d-\d\d): (.+)/)
        string = "I could be made to raise #{$2.inspect} from #{$1}."

        added_code = <<~RUBY
          puts #{string.inspect}
        RUBY

        new_source.insert(loc.end_offset, "\n#{added_code}")
      end
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

Fixme.init
