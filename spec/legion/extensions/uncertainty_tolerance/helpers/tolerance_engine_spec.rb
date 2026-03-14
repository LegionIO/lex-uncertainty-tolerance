# frozen_string_literal: true

RSpec.describe Legion::Extensions::UncertaintyTolerance::Helpers::ToleranceEngine do
  subject(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts at DEFAULT_TOLERANCE' do
      expect(engine.current_tolerance).to eq(
        Legion::Extensions::UncertaintyTolerance::Helpers::Constants::DEFAULT_TOLERANCE
      )
    end

    it 'accepts a custom initial_tolerance' do
      e = described_class.new(initial_tolerance: 0.8)
      expect(e.current_tolerance).to eq(0.8)
    end

    it 'clamps initial_tolerance to [0, 1]' do
      e = described_class.new(initial_tolerance: 1.5)
      expect(e.current_tolerance).to eq(1.0)
    end
  end

  describe '#tolerance_label' do
    it 'returns :moderate at 0.5' do
      expect(engine.tolerance_label).to eq(:moderate)
    end

    it 'returns :highly_tolerant at 0.9' do
      e = described_class.new(initial_tolerance: 0.9)
      expect(e.tolerance_label).to eq(:highly_tolerant)
    end
  end

  describe '#record_decision' do
    it 'creates and stores a decision' do
      decision = engine.record_decision(
        description: 'test', domain: :ops, certainty_level: 0.4
      )
      expect(engine.decisions[decision.id]).to be(decision)
    end

    it 'returns a Decision object' do
      result = engine.record_decision(description: 'test', certainty_level: 0.6)
      expect(result).to be_a(Legion::Extensions::UncertaintyTolerance::Helpers::Decision)
    end

    it 'defaults domain to :general' do
      decision = engine.record_decision(description: 'test', certainty_level: 0.6)
      expect(decision.domain).to eq(:general)
    end
  end

  describe '#resolve_decision' do
    let(:decision) { engine.record_decision(description: 'test', certainty_level: 0.3) }

    it 'returns nil for unknown decision_id' do
      expect(engine.resolve_decision(decision_id: 'nonexistent', outcome: :success)).to be_nil
    end

    it 'resolves a known decision' do
      result = engine.resolve_decision(decision_id: decision.id, outcome: :success)
      expect(result.actual_outcome).to eq(:success)
    end

    it 'boosts tolerance on success under uncertainty' do
      engine_low = described_class.new(initial_tolerance: 0.8)
      d = engine_low.record_decision(description: 'uncertain act', certainty_level: 0.3)
      before = engine_low.current_tolerance
      engine_low.resolve_decision(decision_id: d.id, outcome: :success)
      expect(engine_low.current_tolerance).to be > before
    end

    it 'penalizes tolerance on failure under uncertainty' do
      engine_low = described_class.new(initial_tolerance: 0.8)
      d = engine_low.record_decision(description: 'uncertain act', certainty_level: 0.3)
      before = engine_low.current_tolerance
      engine_low.resolve_decision(decision_id: d.id, outcome: :failure)
      expect(engine_low.current_tolerance).to be < before
    end

    it 'does not adapt tolerance when certainty >= tolerance (no uncertainty)' do
      d = engine.record_decision(description: 'certain act', certainty_level: 0.9)
      before = engine.current_tolerance
      engine.resolve_decision(decision_id: d.id, outcome: :success)
      expect(engine.current_tolerance).to eq(before)
    end
  end

  describe '#decisions_under_uncertainty' do
    before do
      engine.record_decision(description: 'low', certainty_level: 0.2)
      engine.record_decision(description: 'high', certainty_level: 0.9)
    end

    it 'returns decisions below the current tolerance' do
      result = engine.decisions_under_uncertainty
      expect(result.map(&:description)).to include('low')
      expect(result.map(&:description)).not_to include('high')
    end

    it 'accepts a custom threshold' do
      result = engine.decisions_under_uncertainty(threshold: 0.3)
      expect(result.all? { |d| d.certainty_level < 0.3 }).to be true
    end
  end

  describe '#successful_uncertain_decisions' do
    it 'returns only resolved successes where agent acted despite uncertainty' do
      e = described_class.new(initial_tolerance: 0.8)
      d = e.record_decision(description: 'risky success', certainty_level: 0.3)
      e.resolve_decision(decision_id: d.id, outcome: :success)
      expect(e.successful_uncertain_decisions.size).to eq(1)
    end

    it 'excludes failures' do
      e = described_class.new(initial_tolerance: 0.8)
      d = e.record_decision(description: 'risky fail', certainty_level: 0.3)
      e.resolve_decision(decision_id: d.id, outcome: :failure)
      expect(e.successful_uncertain_decisions).to be_empty
    end
  end

  describe '#risk_profile' do
    it 'returns a hash keyed by decision types' do
      engine.record_decision(description: 'c', certainty_level: 0.95)
      profile = engine.risk_profile
      expect(profile.keys).to match_array(
        Legion::Extensions::UncertaintyTolerance::Helpers::Constants::DECISION_TYPES
      )
    end

    it 'counts decisions correctly' do
      2.times { engine.record_decision(description: 'x', certainty_level: 0.95) }
      expect(engine.risk_profile[:certain]).to eq(2)
    end
  end

  describe '#domain_tolerance' do
    it 'returns nil when no resolved decisions for domain' do
      expect(engine.domain_tolerance(domain: :missing)).to be_nil
    end

    it 'returns average certainty of successful decisions in domain' do
      d = engine.record_decision(description: 'x', domain: :code, certainty_level: 0.8)
      engine.resolve_decision(decision_id: d.id, outcome: :success)
      expect(engine.domain_tolerance(domain: :code)).to be_within(0.001).of(0.8)
    end
  end

  describe '#should_act?' do
    it 'returns true when certainty >= current_tolerance' do
      expect(engine.should_act?(certainty: 0.5)).to be true
    end

    it 'returns false when certainty < current_tolerance' do
      expect(engine.should_act?(certainty: 0.3)).to be false
    end
  end

  describe '#comfort_zone_expansion_rate' do
    it 'returns 0.0 with fewer than 2 history entries' do
      expect(engine.comfort_zone_expansion_rate).to eq(0.0)
    end

    it 'returns positive rate after multiple successful uncertain decisions' do
      e = described_class.new(initial_tolerance: 0.6)
      5.times do
        d = e.record_decision(description: 'test', certainty_level: 0.2)
        e.resolve_decision(decision_id: d.id, outcome: :success)
      end
      expect(e.comfort_zone_expansion_rate).to be >= 0.0
    end
  end

  describe '#to_h' do
    it 'includes required keys' do
      h = engine.to_h
      expect(h.keys).to include(
        :current_tolerance, :tolerance_label, :total_decisions, :risk_profile, :history_count
      )
    end
  end
end
