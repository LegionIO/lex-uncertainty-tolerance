# frozen_string_literal: true

module Legion
  module Extensions
    module UncertaintyTolerance
      module Runners
        module UncertaintyTolerance
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def record_uncertain_decision(description:, certainty_level:, domain: :general, **)
            decision = engine.record_decision(
              description:     description,
              domain:          domain,
              certainty_level: certainty_level
            )
            Legion::Logging.debug "[uncertainty_tolerance] recorded decision: id=#{decision.id[0..7]} " \
                                  "domain=#{domain} certainty=#{certainty_level.round(2)} " \
                                  "type=#{decision.decision_type}"
            {
              decision_id:               decision.id,
              domain:                    domain,
              certainty_level:           certainty_level,
              decision_type:             decision.decision_type,
              acted_despite_uncertainty: decision.acted_despite_uncertainty,
              current_tolerance:         engine.current_tolerance
            }
          end

          def resolve_uncertain_decision(decision_id:, outcome:, **)
            decision = engine.resolve_decision(decision_id: decision_id, outcome: outcome)
            unless decision
              Legion::Logging.debug "[uncertainty_tolerance] resolve failed: #{decision_id[0..7]} not found"
              return { resolved: false, reason: :not_found }
            end

            Legion::Logging.info "[uncertainty_tolerance] resolved: id=#{decision_id[0..7]} " \
                                 "outcome=#{outcome} tolerance=#{engine.current_tolerance.round(3)}"
            {
              resolved:          true,
              decision_id:       decision_id,
              outcome:           outcome,
              current_tolerance: engine.current_tolerance,
              tolerance_label:   engine.tolerance_label
            }
          end

          def should_act_assessment(certainty:, **)
            act = engine.should_act?(certainty: certainty)
            gap = (certainty - engine.current_tolerance).round(3)
            Legion::Logging.debug "[uncertainty_tolerance] should_act? certainty=#{certainty.round(2)} " \
                                  "tolerance=#{engine.current_tolerance.round(2)} act=#{act}"
            {
              should_act:        act,
              certainty:         certainty,
              current_tolerance: engine.current_tolerance,
              tolerance_label:   engine.tolerance_label,
              gap:               gap
            }
          end

          def uncertainty_profile(**)
            profile = engine.to_h
            Legion::Logging.debug "[uncertainty_tolerance] profile: tolerance=#{profile[:current_tolerance].round(3)} " \
                                  "label=#{profile[:tolerance_label]} decisions=#{profile[:total_decisions]}"
            profile
          end

          def decisions_under_uncertainty_report(threshold: nil, **)
            decisions = engine.decisions_under_uncertainty(threshold: threshold)
            Legion::Logging.debug "[uncertainty_tolerance] under_uncertainty: count=#{decisions.size}"
            {
              decisions: decisions.map(&:to_h),
              count:     decisions.size,
              threshold: threshold || engine.current_tolerance
            }
          end

          def domain_tolerance_report(domain:, **)
            avg = engine.domain_tolerance(domain: domain)
            Legion::Logging.debug "[uncertainty_tolerance] domain_tolerance: domain=#{domain} avg=#{avg&.round(3)}"
            {
              domain:            domain,
              average_certainty: avg,
              found:             !avg.nil?
            }
          end

          def update_uncertainty_tolerance(tolerance:, **)
            clamped = tolerance.clamp(
              Helpers::Constants::TOLERANCE_FLOOR,
              Helpers::Constants::TOLERANCE_CEILING
            )
            engine.instance_variable_set(:@current_tolerance, clamped)
            Legion::Logging.info "[uncertainty_tolerance] tolerance updated: #{clamped.round(3)} " \
                                 "label=#{engine.tolerance_label}"
            {
              updated:           true,
              current_tolerance: clamped,
              tolerance_label:   engine.tolerance_label
            }
          end

          def uncertainty_tolerance_stats(**)
            {
              current_tolerance:           engine.current_tolerance,
              tolerance_label:             engine.tolerance_label,
              total_decisions:             engine.decisions.size,
              successful_uncertain_count:  engine.successful_uncertain_decisions.size,
              risk_profile:                engine.risk_profile,
              comfort_zone_expansion_rate: engine.comfort_zone_expansion_rate,
              history_count:               engine.history.size
            }
          end

          private

          def engine
            @engine ||= Helpers::ToleranceEngine.new
          end
        end
      end
    end
  end
end
