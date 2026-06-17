require "rails_helper"

RSpec.describe PostsHelper, type: :helper do
  describe "#render_markdown" do
    it "converts bold markdown to strong tags" do
      expect(helper.render_markdown("**bold**")).to include("<strong>bold</strong>")
    end

    it "converts italic markdown to em tags" do
      expect(helper.render_markdown("_italic_")).to include("<em>italic</em>")
    end

    it "converts a heading to an h1 tag" do
      expect(helper.render_markdown("# Heading")).to include("<h1>")
      expect(helper.render_markdown("# Heading")).to include("Heading")
    end

    it "returns html_safe output" do
      result = helper.render_markdown("text")
      expect(result).to be_html_safe
    end
  end
end
