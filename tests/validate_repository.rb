#!/usr/bin/env ruby
# Validate account-wide GitHub issue forms with Ruby's standard YAML parser.
require "yaml"
require "uri"

def fail!(message)
  warn "validation failed: #{message}"
  exit 1
end

def load_yaml(path)
  YAML.safe_load(File.read(path), permitted_classes: [], permitted_symbols: [], aliases: false)
rescue Psych::Exception => e
  fail!("#{path}: invalid YAML (#{e.message.lines.first.strip})")
end

config_path = ".github/ISSUE_TEMPLATE/config.yml"
config = load_yaml(config_path)
fail!("#{config_path}: expected a mapping") unless config.is_a?(Hash)
fail!("#{config_path}: blank_issues_enabled must be boolean") unless [true, false].include?(config["blank_issues_enabled"])

links = config.fetch("contact_links", [])
fail!("#{config_path}: contact_links must be a list") unless links.is_a?(Array)
links.each_with_index do |link, index|
  fail!("#{config_path}: contact link #{index + 1} must be a mapping") unless link.is_a?(Hash)
  %w[name about url].each do |key|
    fail!("#{config_path}: contact link #{index + 1} is missing #{key}") unless link[key].is_a?(String) && !link[key].empty?
  end
  uri = URI.parse(link["url"])
  fail!("#{config_path}: contact link #{index + 1} URL must use HTTPS") unless uri.is_a?(URI::HTTPS) && uri.host
rescue URI::InvalidURIError
  fail!("#{config_path}: contact link #{index + 1} has an invalid URL")
end

forms = Dir.glob(".github/ISSUE_TEMPLATE/*.yml").reject { |path| path == config_path }.sort
fail!("expected bug.yml and feature.yml issue forms") unless %w[.github/ISSUE_TEMPLATE/bug.yml .github/ISSUE_TEMPLATE/feature.yml].all? { |path| forms.include?(path) }

allowed_types = %w[input textarea dropdown checkboxes markdown upload]
forms.each do |path|
  form = load_yaml(path)
  fail!("#{path}: expected a mapping") unless form.is_a?(Hash)
  %w[name description].each do |key|
    fail!("#{path}: #{key} must be a non-empty string") unless form[key].is_a?(String) && !form[key].empty?
  end
  body = form["body"]
  fail!("#{path}: body must be a non-empty list") unless body.is_a?(Array) && !body.empty?

  seen_ids = []
  body.each_with_index do |field, index|
    fail!("#{path}: field #{index + 1} must be a mapping") unless field.is_a?(Hash)
    type = field["type"]
    fail!("#{path}: field #{index + 1} has unsupported type #{type.inspect}") unless allowed_types.include?(type)
    attributes = field["attributes"]
    fail!("#{path}: field #{index + 1} attributes must be a mapping") unless attributes.is_a?(Hash)

    if type == "markdown"
      fail!("#{path}: markdown field #{index + 1} needs attributes.value") unless attributes["value"].is_a?(String)
    else
      id = field["id"]
      fail!("#{path}: field #{index + 1} needs a string id") unless id.is_a?(String) && !id.empty?
      fail!("#{path}: duplicate field id #{id.inspect}") if seen_ids.include?(id)
      seen_ids << id
      fail!("#{path}: field #{index + 1} needs attributes.label") unless attributes["label"].is_a?(String) && !attributes["label"].empty?
    end

    if %w[dropdown checkboxes].include?(type)
      options = attributes["options"]
      fail!("#{path}: field #{index + 1} needs at least one option") unless options.is_a?(Array) && !options.empty?
    end

    validations = field["validations"]
    if validations
      fail!("#{path}: field #{index + 1} validations must be a mapping") unless validations.is_a?(Hash)
      if validations.key?("required")
        fail!("#{path}: field #{index + 1} required must be boolean") unless [true, false].include?(validations["required"])
      end
    end
  end
end

puts "Validated #{forms.length} GitHub issue forms and #{links.length} contact links."
