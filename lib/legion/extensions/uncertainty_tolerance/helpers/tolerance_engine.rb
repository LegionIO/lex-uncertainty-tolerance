# frozen_string_literal: true

module Legion
  module Extensions
    module UncertaintyTolerance
      module Helpers
        class ToleranceEngine
          attr_reader :current_tolerance, :decisions, :history

          def initialize(initial_tolerance: Constants::DEFAULT_TOLERANCE)
            @current_tolerance = initial_tolerance.clamp(
              Constants::TOLERANCE_FLOOR,
              Constants::TOLERANCE_CEILING
            )
            @decisions = {}
            @history   = []
          end

          def tolerance_label
            Constants::TOLERANCE_LABELS.each do |range, label|
              return label if range.cover?(@current_tolerance)
            end
            :unknown
          end

          def record_decision(description:, certainty_level:, domain: :general)
            decision = Decision.new(
              description:       description,
              domain:            domain,
              certainty_level:   certainty_level,
              tolerance_at_time: @current_tolerance
            )
            @decisions[decision.id] = decision
            prune_decisions
            decision
          end

          def resolve_decision(decision_id:, outcome:)
            decision = @decisions[decision_id]
            return nil unless decision

            decision.resolve!(outcome: outcome)
            record_history(decision)
            adapt_tolerance(decision)
            decision
          end

          def decisions_under_uncertainty(threshold: nil)
            cutoff = threshold || @current_tolerance
            @decisions.values.select { |d| d.certainty_level < cutoff }
          end

          def successful_uncertain_decisions
            @decisions.values.select do |d|
              d.acted_despite_uncertainty && d.successful?
            end
          end

          def risk_profile
            breakdown = Constants::DECISION_TYPES.to_h { |t| [t, 0] }
            @decisions.each_value { |d| breakdown[d.decision_type] += 1 }
            breakdown
          end

          def domain_tolerance(domain:)
            resolved = @decisions.values.select do |d|
              d.domain == domain && d.successful? && !d.actual_outcome.nil?
            end
            return nil if resolved.empty?

            resolved.sum(&:certainty_level) / resolved.size
          end

          def should_act?(certainty:)
            certainty >= @current_tolerance
          end

          def comfort_zone_expansion_rate
            return 0.0 if @history.size < 2

            tolerances = @history.last(10).map { |h| h[:tolerance_snapshot] }
            return 0.0 if tolerances.size < 2

            (tolerances.last - tolerances.first) / (tolerances.size - 1).to_f
          end

          def to_h
            {
              current_tolerance: @current_tolerance,
              tolerance_label:   tolerance_label,
              total_decisions:   @decisions.size,
              risk_profile:      risk_profile,
              history_count:     @history.size
            }
          end

          private

          def adapt_tolerance(decision)
            return unless decision.acted_despite_uncertainty

            delta = if decision.successful?
                      Constants::POSITIVE_OUTCOME_BOOST
                    else
                      -Constants::NEGATIVE_OUTCOME_PENALTY
                    end

            @current_tolerance = (@current_tolerance + delta).clamp(
              Constants::TOLERANCE_FLOOR,
              Constants::TOLERANCE_CEILING
            )
          end

          def record_history(decision)
            @history << {
              decision_id:        decision.id,
              outcome:            decision.actual_outcome,
              certainty_level:    decision.certainty_level,
              tolerance_snapshot: @current_tolerance,
              recorded_at:        Time.now.utc
            }
            @history.shift while @history.size > Constants::MAX_HISTORY
          end

          def prune_decisions
            return unless @decisions.size > Constants::MAX_DECISIONS

            oldest_keys = @decisions.keys.first(@decisions.size - Constants::MAX_DECISIONS)
            oldest_keys.each { |k| @decisions.delete(k) }
          end
        end
      end
    end
  end
end
