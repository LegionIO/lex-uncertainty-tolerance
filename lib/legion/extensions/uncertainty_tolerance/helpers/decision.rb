# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module UncertaintyTolerance
      module Helpers
        class Decision
          attr_reader :id, :description, :domain, :certainty_level,
                      :tolerance_at_time, :acted_despite_uncertainty, :created_at
          attr_accessor :actual_outcome

          def initialize(description:, domain:, certainty_level:, tolerance_at_time:)
            @id                      = SecureRandom.uuid
            @description             = description
            @domain                  = domain
            @certainty_level         = certainty_level.clamp(0.0, 1.0)
            @tolerance_at_time       = tolerance_at_time
            @actual_outcome          = nil
            @acted_despite_uncertainty = certainty_level < tolerance_at_time
            @created_at = Time.now.utc
          end

          def resolve!(outcome:)
            @actual_outcome = outcome
            self
          end

          def successful?
            @actual_outcome == :success
          end

          def risky?
            @certainty_level < 0.4
          end

          def decision_type
            Constants::CERTAINTY_THRESHOLDS.each do |type, threshold|
              return type if @certainty_level >= threshold
            end
            :unknown
          end

          def to_h
            {
              id:                        @id,
              description:               @description,
              domain:                    @domain,
              certainty_level:           @certainty_level,
              actual_outcome:            @actual_outcome,
              tolerance_at_time:         @tolerance_at_time,
              decision_type:             decision_type,
              acted_despite_uncertainty: @acted_despite_uncertainty,
              created_at:                @created_at
            }
          end
        end
      end
    end
  end
end
