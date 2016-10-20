require 'puppet/provider/parsedfile'

Puppet::Type.type(:incron).provide(:incrontab, :parent => Puppet::Provider::ParsedFile, :default_target => "/var/spool/incron/" + ENV["USER"], :filetype => :flat) do
  commands :incrontab => "incrontab"

  text_line :comment, :match => %r{^\s*#}, :post_parse => proc { |record|
    record[:name] = $1 if record[:line] =~ /Puppet Name: (.+)\s*$/
  }

  text_line :blank, :match => %r{^\s*$}

  record_line :incrontab, :fields => %w{path mask command},
    :block_eval => :instance do

    def to_line(record)
      str = ""
      str = "# Puppet Name: #{record[:name]}\n" if record[:name]
      str += record.values_at(*fields).map do |field|
        if field.nil? or field == :absent
          self.absent
        else
          field
        end
      end.join(self.joiner)
      str
    end
  end

  # Return the header placed at the top of each generated file, warning
  # users that modifying this file manually is probably a bad idea.
  def self.header
%{}
  end

  # Collapse name and env records.
  def self.prefetch_hook(records)
    name = nil
    result = records.each { |record|
      case record[:record_type]
      when :comment
        if record[:name]
          name = record[:name]
          record[:skip] = true

        end
      when :blank
        # nothing
      else
        if name
          record[:name] = name
          name = nil
        end
      end
    }.reject { |record| record[:skip] }
    result
  end
end

