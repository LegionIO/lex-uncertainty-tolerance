# frozen_string_literal: true

RSpec.describe Legion::Extensions::UncertaintyTolerance::Helpers::Decision do
  let(:decision) do
    described_class.new(
      description:       'deploy to production',
      domain:            :ops,
      certainty_level:   0.6,
      tolerance_at_time: 0.5
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(decision.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'clamps certainty_level to [0, 1]' do
      d = described_class.new(
        description: 'test', domain: :test, certainty_level: 1.5, tolerance_at_time: 0.5
      )
      expect(d.certainty_level).to eq(1.0)
    end

    it 'sets acted_despite_uncertainty true when certainty < tolerance' do
      d = described_class.new(
        description: 'risky', domain: :test, certainty_level: 0.3, tolerance_at_time: 0.5
      )
      expect(d.acted_despite_uncertainty).to be true
    end

    it 'sets acted_despite_uncertainty false when certainty >= tolerance' do
      expect(decision.acted_despite_uncertainty).to be false
    end

    it 'starts with nil actual_outcome' do
      expect(decision.actual_outcome).to be_nil
    end
  end

  describe '#resolve!' do
    it 'sets actual_outcome and returns self' do
      result = decision.resolve!(outcome: :success)
      expect(decision.actual_outcome).to eq(:success)
      expect(result).to be(decision)
    end
  end

  describe '#successful?' do
    it 'returns true after :success outcome' do
      decision.resolve!(outcome: :success)
      expect(decision.successful?).to be true
    end

    it 'returns false after :failure outcome' do
      decision.resolve!(outcome: :failure)
      expect(decision.successful?).to be false
    end

    it 'returns false when unresolved' do
      expect(decision.successful?).to be false
    end
  end

  describe '#risky?' do
    it 'returns true when certainty < 0.4' do
      d = described_class.new(
        description: 'risky', domain: :test, certainty_level: 0.3, tolerance_at_time: 0.5
      )
      expect(d.risky?).to be true
    end

    it 'returns false when certainty >= 0.4' do
      expect(decision.risky?).to be false
    end
  end

  describe '#decision_type' do
    it 'returns :certain for certainty 0.95' do
      d = described_class.new(
        description: 'test', domain: :test, certainty_level: 0.95, tolerance_at_time: 0.5
      )
      expect(d.decision_type).to eq(:certain)
    end

    it 'returns :probable for certainty 0.75' do
      d = described_class.new(
        description: 'test', domain: :test, certainty_level: 0.75, tolerance_at_time: 0.5
      )
      expect(d.decision_type).to eq(:probable)
    end

    it 'returns :uncertain for certainty 0.55' do
      d = described_class.new(
        description: 'test', domain: :test, certainty_level: 0.55, tolerance_at_time: 0.5
      )
      expect(d.decision_type).to eq(:uncertain)
    end

    it 'returns :ambiguous for certainty 0.35' do
      d = described_class.new(
        description: 'test', domain: :test, certainty_level: 0.35, tolerance_at_time: 0.5
      )
      expect(d.decision_type).to eq(:ambiguous)
    end

    it 'returns :unknown for certainty 0.0' do
      d = described_class.new(
        description: 'test', domain: :test, certainty_level: 0.0, tolerance_at_time: 0.5
      )
      expect(d.decision_type).to eq(:unknown)
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = decision.to_h
      expect(h.keys).to include(
        :id, :description, :domain, :certainty_level,
        :actual_outcome, :tolerance_at_time, :decision_type,
        :acted_despite_uncertainty, :created_at
      )
    end
  end
end
