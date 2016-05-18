require "spec_helper"

describe Spree::Variant::PriceGenerator do
  let(:tax_category) { create(:tax_category) }
  let(:product) { variant.product }
  let(:variant) { create(:variant, price: 10) }
  let(:germany) { create(:country, iso: "DE") }
  let(:germany_zone) { create(:zone, countries: [germany]) }
  let!(:german_vat) { create(:tax_rate, included_in_price: true, amount: 0.19, zone: germany_zone, tax_category: tax_category) }

  subject { described_class.new(variant).run }

  context "with Germany as default admin country" do
    let(:france) { create(:country, iso: "FR") }
    let(:france_zone) { create(:zone, countries: [france]) }
    let!(:french_vat) { create(:tax_rate, included_in_price: true, amount: 0.20, zone: france_zone, tax_category: tax_category) }

    before do
      Spree::Config.admin_vat_country_iso = "DE"
    end

    it "builds a correct price including VAT for all VAT countries" do
      subject
      expect(variant.default_price.for_any_country?).to be false
      expect(variant.prices.detect { |p| p.country_iso == "DE" }.try!(:amount)).to eq(10.00)
      expect(variant.prices.detect { |p| p.country_iso == "FR"}.try!(:amount)).to eq(10.08)
      expect(variant.prices.detect { |p| p.country_iso.nil? }.try!(:amount)).to eq(8.40)
    end

    it "will not build prices that are already present" do
      variant.prices.build(amount: 11, country_iso: "FR")
      variant.prices.build(amount: 11, country_iso: nil)
      expect { subject }.not_to change { variant.prices.length }
    end
  end

  context "with no default admin country" do
    let(:france) { create(:country, iso: "FR") }
    let(:france_zone) { create(:zone, countries: [france]) }
    let!(:french_vat) { create(:tax_rate, included_in_price: true, amount: 0.20, zone: france_zone, tax_category: tax_category) }

    it "builds a correct price including VAT for all VAT countries" do
      subject
      expect(variant.default_price.for_any_country?).to be true
      expect(variant.prices.detect { |p| p.country_iso == "DE" }.try!(:amount)).to eq(11.90)
      expect(variant.prices.detect { |p| p.country_iso == "FR" }.try!(:amount)).to eq(12.00)
      expect(variant.prices.detect { |p| p.country_iso.nil? }.try!(:amount)).to eq(10.00)
    end
  end
end