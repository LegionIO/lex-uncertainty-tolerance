# frozen_string_literal: true

RSpec.describe Legion::Extensions::UncertaintyTolerance::Helpers::Constants do
  describe 'TOLERANCE_LABELS' do
    subject(:labels) { described_class::TOLERANCE_LABELS }

    it 'maps 0.9 to :highly_tolerant' do
      match = labels.find { |range, _| range.cover?(0.9) }
      expect(match.last).to eq(:highly_tolerant)
    end

    it 'maps 0.7 to :tolerant' do
      match = labels.find { |range, _| range.cover?(0.7) }
      expect(match.last).to eq(:tolerant)
    end

    it 'maps 0.5 to :moderate' do
      match = labels.find { |range, _| range.cover?(0.5) }
      expect(match.last).to eq(:moderate)
    end

    it 'maps 0.3 to :intolerant' do
      match = labels.find { |range, _| range.cover?(0.3) }
      expect(match.last).to eq(:intolerant)
    end

    it 'maps 0.1 to :highly_intolerant' do
      match = labels.find { |range, _| range.cover?(0.1) }
      expect(match.last).to eq(:highly_intolerant)
    end
  end

  describe 'DECISION_TYPES' do
    it 'contains exactly 5 types' do
      expect(described_class::DECISION_TYPES.size).to eq(5)
    end

    it 'includes :unknown' do
      expect(described_class::DECISION_TYPES).to include(:unknown)
    end
  end

  describe 'CERTAINTY_THRESHOLDS' do
    it 'has :certain at 0.9' do
      expect(described_class::CERTAINTY_THRESHOLDS[:certain]).to eq(0.9)
    end

    it 'has :unknown at 0.0' do
      expect(described_class::CERTAINTY_THRESHOLDS[:unknown]).to eq(0.0)
    end
  end

  describe 'numeric constants' do
    it 'DEFAULT_TOLERANCE is 0.5' do
      expect(described_class::DEFAULT_TOLERANCE).to eq(0.5)
    end

    it 'POSITIVE_OUTCOME_BOOST is less than NEGATIVE_OUTCOME_PENALTY' do
      expect(described_class::POSITIVE_OUTCOME_BOOST).to be < described_class::NEGATIVE_OUTCOME_PENALTY
    end
  end
end
