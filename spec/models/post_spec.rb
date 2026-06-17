require "rails_helper"

RSpec.describe Post, type: :model do
  describe "factory" do
    it "is valid" do
      expect(build(:post)).to be_valid
    end
  end

  describe "scoping" do
    it "does not include unpublished posts" do
      published = create(:post, published_at: 1.day.ago)
      unpublished = create(:post, published_at: nil, slug: "unpublished")

      results = Post.where.not(published_at: nil)

      expect(results).to include(published)
      expect(results).not_to include(unpublished)
    end

    it "orders by published_at descending" do
      older = create(:post, published_at: 2.days.ago, slug: "older-post")
      newer = create(:post, published_at: 1.day.ago, slug: "newer-post")

      results = Post.where.not(published_at: nil).order(published_at: :desc)

      expect(results.first).to eq(newer)
      expect(results.last).to eq(older)
    end
  end
end
