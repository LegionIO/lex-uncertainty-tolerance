# lex-uncertainty-tolerance

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-uncertainty-tolerance`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::UncertaintyTolerance`

## Purpose

Models the agent's capacity to act under uncertainty. Tracks a tolerance score that adapts based on outcome history — successful uncertain decisions increase tolerance; failed uncertain decisions decrease it. Supports per-domain tolerance profiling, `should_act?` threshold checking, and decision risk profiling. Helps the agent calibrate how much uncertainty is acceptable before deferring or requesting more information.

## Gem Info

- **Gem name**: `lex-uncertainty-tolerance`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/uncertainty_tolerance/
  version.rb                                # VERSION = '0.1.0'
  helpers/
    constants.rb                            # tolerance labels, decision types, certainty thresholds, limits, rates
    decision.rb                             # Decision class — single decision with certainty and outcome tracking
    tolerance_engine.rb                     # ToleranceEngine class — tolerance store with domain profiling
  runners/
    uncertainty_tolerance.rb                # Runners::UncertaintyTolerance module — all public runner methods
  client.rb                                 # Client class including Runners::UncertaintyTolerance
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `TOLERANCE_LABELS` | hash | Named tiers: `very_low`, `low`, `moderate`, `high`, `very_high` based on tolerance value |
| `DECISION_TYPES` | 5 symbols | `:action`, `:delegation`, `:deferral`, `:consultation`, `:abstention` |
| `CERTAINTY_THRESHOLDS` | hash | Named certainty levels: `certain`, `confident`, `moderate`, `uncertain`, `very_uncertain` |
| `MAX_DECISIONS` | 300 | Maximum decision records |
| `MAX_HISTORY` | 500 | Maximum outcome history entries |
| `DEFAULT_TOLERANCE` | 0.5 | Starting tolerance |
| `ADAPTATION_RATE` | 0.05 | Tolerance shift rate on resolution |
| `POSITIVE_OUTCOME_BOOST` | 0.03 | Tolerance increase on successful uncertain decision |
| `NEGATIVE_OUTCOME_PENALTY` | 0.05 | Tolerance decrease on failed uncertain decision |

## Helpers

### `Helpers::Decision`

Single decision with certainty and outcome tracking.

- `initialize(id:, description:, certainty:, domain: :general, decision_type: :action)` — tolerance_at_time snapshot captured at creation, resolved=false, outcome=nil
- `certainty_level` — maps certainty to CERTAINTY_THRESHOLDS label
- `acted_despite_uncertainty` — `certainty < tolerance_at_time` (acted when uncertain)
- `resolve!(outcome:)` — sets resolved=true, stores outcome
- `successful?` — outcome == :success
- `risky?` — certainty < 0.4
- `decision_type` — returns the stored decision_type symbol

### `Helpers::ToleranceEngine`

Tolerance store with decision log and domain profiling.

- `initialize` — decisions hash, history array, tolerance = DEFAULT_TOLERANCE, domain_tolerances hash
- `record_decision(description:, certainty:, domain: :general, decision_type: :action)` — creates Decision with current tolerance snapshot; returns nil if at MAX_DECISIONS
- `resolve_decision(decision_id:, outcome:)` — calls `decision.resolve!`; then calls `adapt_tolerance(domain:, decision:)` to adjust tolerance and domain_tolerance
- `adapt_tolerance(domain:, decision:)` — if `decision.acted_despite_uncertainty`:
  - `outcome == :success`: `tolerance += POSITIVE_OUTCOME_BOOST`, `domain_tolerance[domain] += POSITIVE_OUTCOME_BOOST`
  - `outcome == :failure`: `tolerance -= NEGATIVE_OUTCOME_PENALTY`, `domain_tolerance[domain] -= NEGATIVE_OUTCOME_PENALTY`
  - Both clamped 0.0–1.0
- `decisions_under_uncertainty` — decisions where `certainty < tolerance_at_time`
- `successful_uncertain_decisions` — subset where `successful? == true`
- `risk_profile` — distribution of risky decisions across domains
- `domain_tolerance(domain)` — returns domain-specific tolerance or global tolerance if not set
- `should_act?(certainty:, domain: nil)` — `certainty >= domain_tolerance(domain)`
- `comfort_zone_expansion_rate` — fraction of uncertain decisions that were successful (positive adaptation ratio)

## Runners

All runners are in `Runners::UncertaintyTolerance`. The `Client` includes this module and owns a `ToleranceEngine` instance.

Note: `update_uncertainty_tolerance` uses `instance_variable_set` directly to inject a pre-built engine for testing or external initialization.

| Runner | Parameters | Returns |
|---|---|---|
| `record_uncertain_decision` | `description:, certainty:, domain: :general, decision_type: :action` | `{ success:, decision_id:, certainty:, tolerance_at_time:, risky: }` |
| `resolve_uncertain_decision` | `decision_id:, outcome:` | `{ success:, decision_id:, outcome:, tolerance: }` |
| `should_act_assessment` | `certainty:, domain: nil` | `{ success:, should_act:, certainty:, tolerance:, margin: }` |
| `uncertainty_profile` | (none) | `{ success:, tolerance:, label:, decisions_under_uncertainty:, comfort_zone_expansion_rate: }` |
| `decisions_under_uncertainty_report` | (none) | `{ success:, decisions:, count:, successful_count: }` |
| `domain_tolerance_report` | (none) | `{ success:, domain_tolerances:, global_tolerance: }` |
| `update_uncertainty_tolerance` | `engine: nil` | Uses `instance_variable_set` to inject engine; returns `{ success: }` |
| `uncertainty_tolerance_stats` | (none) | Total decisions, tolerance, label, domain breakdown |

## Integration Points

- **lex-tick / lex-cortex**: `should_act_assessment` can be called from the `action_selection` phase before executing any action with certainty below the global tolerance
- **lex-consent**: uncertainty tolerance informs the consent tier boundary — low tolerance should push actions toward `:consult` or `:defer` tiers
- **lex-prediction**: prediction confidence is the `certainty` input to `should_act_assessment`; unresolved predictions can be auto-resolved through outcome feedback
- **lex-self-model**: self-model's competence scores provide a complementary certainty signal; low competence + low uncertainty tolerance = strong deferral
- **lex-volition**: DriveSynthesizer epistemic drive complements uncertainty tolerance — when tolerance is low, epistemic drive pushes for more information before acting

## Development Notes

- `tolerance_at_time` is captured at decision creation — this is intentional; it records the tolerance level at the moment the decision was made, for later analysis of whether the agent was within its comfort zone
- `adapt_tolerance` only adjusts on `acted_despite_uncertainty` — decisions made with high certainty do not change tolerance (only risky decisions that were acted upon produce learning)
- `NEGATIVE_OUTCOME_PENALTY = 0.05` > `POSITIVE_OUTCOME_BOOST = 0.03` — failures reduce tolerance faster than successes increase it; this creates conservative adaptation, matching the asymmetric cognitive bias toward loss
- `should_act?` uses `domain_tolerance(domain)` which falls back to global tolerance — per-domain calibration is supported but not required
- `update_uncertainty_tolerance` using `instance_variable_set` is a testing/injection hook, not the normal runtime path
