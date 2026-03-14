# frozen_string_literal: true

module Legion
  module Extensions
    module UncertaintyTolerance
      module Helpers
        module Constants
          TOLERANCE_LABELS = {
            (0.8..)     => :highly_tolerant,
            (0.6...0.8) => :tolerant,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :intolerant,
            (..0.2)     => :highly_intolerant
          }.freeze

          DECISION_TYPES = %i[certain probable uncertain ambiguous unknown].freeze

          CERTAINTY_THRESHOLDS = {
            certain:   0.9,
            probable:  0.7,
            uncertain: 0.5,
            ambiguous: 0.3,
            unknown:   0.0
          }.freeze

          MAX_DECISIONS        = 300
          MAX_HISTORY          = 500
          DEFAULT_TOLERANCE    = 0.5
          TOLERANCE_FLOOR      = 0.0
          TOLERANCE_CEILING    = 1.0
          ADAPTATION_RATE      = 0.05
          POSITIVE_OUTCOME_BOOST   = 0.03
          NEGATIVE_OUTCOME_PENALTY = 0.05
        end
      end
    end
  end
end
