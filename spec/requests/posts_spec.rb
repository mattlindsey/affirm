require "rails_helper"

RSpec.describe "Posts", type: :request do
  before { sign_in_test_user }

  describe "GET /posts" do
    it "returns success" do
      get posts_path
      expect(response).to have_http_status(:success)
    end

    it "lists published posts" do
      post = create(:post, title: "Hello World")
      get posts_path
      expect(response.body).to include("Hello World")
    end

    it "does not list unpublished posts" do
      create(:post, :unpublished, title: "Draft Post")
      get posts_path
      expect(response.body).not_to include("Draft Post")
    end

    it "shows posts newest first" do
      older = create(:post, title: "Older Post", published_at: 2.days.ago)
      newer = create(:post, title: "Newer Post", published_at: 1.day.ago)
      get posts_path
      expect(response.body.index("Newer Post")).to be < response.body.index("Older Post")
    end
  end

  describe "GET /posts/:slug" do
    let(:blog_post) { create(:post, title: "My Post", body: "Hello **world**") }

    it "returns success" do
      get post_path(blog_post.slug)
      expect(response).to have_http_status(:success)
    end

    it "displays the post title" do
      get post_path(blog_post.slug)
      expect(response.body).to include("My Post")
    end

    it "renders the body as HTML via render_markdown" do
      get post_path(blog_post.slug)
      expect(response.body).to include("<strong>world</strong>")
    end

    it "returns 404 for unknown slug" do
      get post_path("no-such-post")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "authentication" do
    it "redirects unauthenticated users to login" do
      delete logout_path
      get posts_path
      expect(response).to redirect_to(login_path)
    end
  end
end
