# frozen_string_literal: true

require 'legion/extensions/uncertainty_tolerance/client'

RSpec.describe Legion::Extensions::UncertaintyTolerance::Runners::UncertaintyTolerance do
  let(:client) { Legion::Extensions::UncertaintyTolerance::Client.new }

  describe '#record_uncertain_decision' do
    it 'records a decision and returns structured response' do
      result = client.record_uncertain_decision(
        description:     'deploy service',
        certainty_level: 0.4,
        domain:          :ops
      )
      expect(result[:decision_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:certainty_level]).to eq(0.4)
      expect(result[:domain]).to eq(:ops)
      expect(result[:current_tolerance]).to be_a(Float)
    end

    it 'computes acted_despite_uncertainty flag' do
      result = client.record_uncertain_decision(
        description:     'risky action',
        certainty_level: 0.2
      )
      expect(result[:acted_despite_uncertainty]).to be true
    end

    it 'includes decision_type in response' do
      result = client.record_uncertain_decision(
        description:     'probable action',
        certainty_level: 0.75
      )
      expect(result[:decision_type]).to eq(:probable)
    end
  end

  describe '#resolve_uncertain_decision' do
    let(:decision_id) do
      client.record_uncertain_decision(
        description: 'test', certainty_level: 0.3
      )[:decision_id]
    end

    it 'resolves a known decision' do
      result = client.resolve_uncertain_decision(decision_id: decision_id, outcome: :success)
      expect(result[:resolved]).to be true
      expect(result[:outcome]).to eq(:success)
    end

    it 'returns resolved: false for unknown id' do
      result = client.resolve_uncertain_decision(decision_id: 'bad-id', outcome: :success)
      expect(result[:resolved]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'includes updated tolerance in response' do
      result = client.resolve_uncertain_decision(decision_id: decision_id, outcome: :success)
      expect(result[:current_tolerance]).to be_a(Float)
      expect(result[:tolerance_label]).to be_a(Symbol)
    end
  end

  describe '#should_act_assessment' do
    it 'returns should_act: true when certainty meets tolerance' do
      result = client.should_act_assessment(certainty: 0.9)
      expect(result[:should_act]).to be true
    end

    it 'returns should_act: false when certainty is below tolerance' do
      result = client.should_act_assessment(certainty: 0.1)
      expect(result[:should_act]).to be false
    end

    it 'includes gap in response' do
      result = client.should_act_assessment(certainty: 0.7)
      expect(result[:gap]).to be_a(Float)
    end
  end

  describe '#uncertainty_profile' do
    it 'returns profile hash with expected keys' do
      result = client.uncertainty_profile
      expect(result.keys).to include(
        :current_tolerance, :tolerance_label, :total_decisions, :risk_profile
      )
    end
  end

  describe '#decisions_under_uncertainty_report' do
    before do
      client.record_uncertain_decision(description: 'low certainty', certainty_level: 0.1)
      client.record_uncertain_decision(description: 'high certainty', certainty_level: 0.9)
    end

    it 'returns decisions below threshold' do
      result = client.decisions_under_uncertainty_report
      expect(result[:count]).to be >= 1
      expect(result[:decisions]).to all(include(:certainty_level))
    end

    it 'accepts a custom threshold' do
      result = client.decisions_under_uncertainty_report(threshold: 0.2)
      expect(result[:threshold]).to eq(0.2)
    end
  end

  describe '#domain_tolerance_report' do
    it 'returns found: false when domain has no data' do
      result = client.domain_tolerance_report(domain: :unknown_domain)
      expect(result[:found]).to be false
    end

    it 'returns average certainty when successful decisions exist' do
      id = client.record_uncertain_decision(
        description: 'code review', domain: :code, certainty_level: 0.85
      )[:decision_id]
      client.resolve_uncertain_decision(decision_id: id, outcome: :success)
      result = client.domain_tolerance_report(domain: :code)
      expect(result[:found]).to be true
      expect(result[:average_certainty]).to be_within(0.01).of(0.85)
    end
  end

  describe '#update_uncertainty_tolerance' do
    it 'updates tolerance to clamped value' do
      result = client.update_uncertainty_tolerance(tolerance: 0.7)
      expect(result[:updated]).to be true
      expect(result[:current_tolerance]).to eq(0.7)
    end

    it 'clamps values above 1.0' do
      result = client.update_uncertainty_tolerance(tolerance: 1.5)
      expect(result[:current_tolerance]).to eq(1.0)
    end

    it 'clamps values below 0.0' do
      result = client.update_uncertainty_tolerance(tolerance: -0.5)
      expect(result[:current_tolerance]).to eq(0.0)
    end
  end

  describe '#uncertainty_tolerance_stats' do
    it 'returns comprehensive stats' do
      result = client.uncertainty_tolerance_stats
      expect(result.keys).to include(
        :current_tolerance,
        :tolerance_label,
        :total_decisions,
        :successful_uncertain_count,
        :risk_profile,
        :comfort_zone_expansion_rate,
        :history_count
      )
    end
  end
end
