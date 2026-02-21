# frozen_string_literal: true

require "zip"
require "nokogiri"
require "cgi"

class DocxPlaceholderService
  # Only supports {{PLACEHOLDER}} with A-Z, 0-9 and _ characters for now. No spaces or other chars.
  PLACEHOLDER_REGEX = /\{\{([A-Za-z0-9_]+)\}\}/.freeze

  XML_TARGETS = [
    "word/document.xml"
  ].freeze

  def initialize(active_storage_attachment_or_blob)
    @attachment = active_storage_attachment_or_blob
  end

  def placeholders
    xml_entries = read_target_xml_entries
    found = xml_entries.flat_map do |(_, xml)|
      xml.scan(PLACEHOLDER_REGEX).flatten
    end
    found.uniq.sort
  end

  # values: { "NAME" => "Niko", ... }
  # returns binary string .docx
  def render(values)
    values = values.transform_keys(&:to_s)
    input_bytes = attachment_bytes

    buffer = Zip::OutputStream.write_buffer do |zos|
      Zip::File.open_buffer(input_bytes) do |zip|
        zip.each do |entry|
          data = entry.get_input_stream.read
          data = replace_placeholders_in_xml(data, values) if target_xml_path?(entry.name)

          zos.put_next_entry(entry.name)
          zos.write(data)
        end
      end
    end

    buffer.string
  end

  private

  def attachment_bytes
    if @attachment.respond_to?(:download)
      @attachment.download
    else
      @attachment.blob.download
    end
  end

  def target_xml_path?(path)
    return true if XML_TARGETS.include?(path)
    return true if path.start_with?("word/header") && path.end_with?(".xml")
    return true if path.start_with?("word/footer") && path.end_with?(".xml")
    false
  end

  def read_target_xml_entries
    bytes = attachment_bytes
    entries = []

    Zip::File.open_buffer(bytes) do |zip|
      zip.each do |entry|
        next unless target_xml_path?(entry.name)
        entries << [entry.name, entry.get_input_stream.read]
      end
    end

    entries
  end

  def replace_placeholders_in_xml(xml_str, values)
    s = xml_str.dup
    s.force_encoding("UTF-8")
    unless s.valid_encoding?
      s = s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "�")
    end

    s.gsub(PLACEHOLDER_REGEX) do
      key = Regexp.last_match(1)
      val = values.fetch(key, "{{#{key}}}")

      escaped = CGI.escapeHTML(val.to_s)
      escaped.force_encoding("UTF-8")
      escaped = escaped.encode("UTF-8", invalid: :replace, undef: :replace, replace: "") unless escaped.valid_encoding?
      escaped
    end
  end

end
