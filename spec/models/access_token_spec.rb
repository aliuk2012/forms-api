require "rails_helper"

RSpec.describe AccessToken, type: :model do
  subject(:access_token) { described_class.new }

  it "has a valid factory" do
    access_token = create :access_token
    expect(access_token).to be_valid
  end

  describe "validations" do
    it "requires a token" do
      expect(access_token).to be_invalid
      expect(access_token.errors[:token]).to include("can't be blank")
    end

    it "requires an owner" do
      expect(access_token).to be_invalid
      expect(access_token.errors[:owner]).to include("can't be blank")
    end
  end

  describe "scopes" do
    describe "#active" do
      let(:active_tokens) { create_list :access_token, 3 }
      let(:deactivated_tokens) { create_list :access_token, 3, deactivated_at: Time.zone.now }

      before do
        active_tokens
        deactivated_tokens
      end

      it "returns active tokens" do
        expect(described_class.active).to eq(active_tokens)
      end

      it "does not return deactivated tokens" do
        expect(described_class.active).not_to eq(deactivated_tokens)
      end
    end
  end
end
