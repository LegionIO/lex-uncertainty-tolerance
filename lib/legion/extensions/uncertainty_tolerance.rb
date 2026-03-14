# frozen_string_literal: true

require 'legion/extensions/uncertainty_tolerance/version'
require 'legion/extensions/uncertainty_tolerance/helpers/constants'
require 'legion/extensions/uncertainty_tolerance/helpers/decision'
require 'legion/extensions/uncertainty_tolerance/helpers/tolerance_engine'
require 'legion/extensions/uncertainty_tolerance/runners/uncertainty_tolerance'

module Legion
  module Extensions
    module UncertaintyTolerance
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
