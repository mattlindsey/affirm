module PostsHelper
  def render_markdown(text)
    Commonmarker.to_html(text).html_safe
  end
end
