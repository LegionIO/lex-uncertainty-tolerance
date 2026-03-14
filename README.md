# lex-uncertainty-tolerance

Uncertainty tolerance modeling for LegionIO cognitive agents. Tracks the agent's capacity to act under uncertainty, adapting tolerance up or down based on outcomes.

## What It Does

`lex-uncertainty-tolerance` models how much uncertainty the agent can tolerate before deferring a decision. A global tolerance score starts at 0.5 and adapts over time: successful decisions made under uncertainty increase tolerance; failed uncertain decisions decrease it. Per-domain tolerances are tracked separately. The `should_act?` query returns whether a given certainty level clears the current threshold.

- **Tolerance adaptation**: `+0.03` on successful uncertain decision; `-0.05` on failed uncertain decision
- **Per-domain tolerances**: separate tolerance per domain, falls back to global
- **should_act?**: `certainty >= tolerance` returns true to proceed
- **Decisions under uncertainty**: `certainty < tolerance_at_time` (acted despite uncertainty)
- **Comfort zone expansion rate**: fraction of uncertain decisions that succeeded

## Usage

```ruby
require 'legion/extensions/uncertainty_tolerance'

client = Legion::Extensions::UncertaintyTolerance::Client.new

# Record a decision
result = client.record_uncertain_decision(
  description: 'deploy with partial test coverage',
  certainty: 0.4,
  domain: :engineering,
  decision_type: :action
)
decision_id = result[:decision_id]
# risky: true (certainty < 0.4)

# Check if agent should act at a given certainty
client.should_act_assessment(certainty: 0.45, domain: :engineering)
# => { should_act: false, certainty: 0.45, tolerance: 0.5, margin: -0.05 }

# Resolve the decision (adapt tolerance based on outcome)
client.resolve_uncertain_decision(decision_id: decision_id, outcome: :success)
# => { tolerance: 0.53 }  (increased because acted despite uncertainty + success)

# Check again after successful outcome
client.should_act_assessment(certainty: 0.45, domain: :engineering)
# => { should_act: false, certainty: 0.45, tolerance: 0.53, margin: -0.08 }

# Overall profile
client.uncertainty_profile
# => { tolerance: 0.53, label: :moderate, decisions_under_uncertainty: 1, comfort_zone_expansion_rate: 1.0 }

# Domain breakdown
client.domain_tolerance_report
# => { domain_tolerances: { engineering: 0.53 }, global_tolerance: 0.53 }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
