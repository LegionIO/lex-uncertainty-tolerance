# frozen_string_literal: true

require_relative 'lib/legion/extensions/uncertainty_tolerance/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-uncertainty-tolerance'
  spec.version       = Legion::Extensions::UncertaintyTolerance::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Uncertainty Tolerance'
  spec.description   = 'Models individual differences in tolerance for ambiguity and uncertainty for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-uncertainty-tolerance'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-uncertainty-tolerance'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-uncertainty-tolerance'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-uncertainty-tolerance'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-uncertainty-tolerance/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-uncertainty-tolerance.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
