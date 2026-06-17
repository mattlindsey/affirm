# lib/tasks/import_posts.rake
require "yaml"

namespace :posts do
  task import: :environment do
    Dir[Rails.root.join("posts/*.md")].each do |file|
      content = File.read(file)
      frontmatter, body = content.split("---\n", 3).drop(1)
      meta = YAML.safe_load(frontmatter, permitted_classes: [ Date, Time, DateTime ])

      Post.find_or_create_by(slug: meta["slug"]).update!(
        title: meta["title"],
        published_at: meta["published_at"],
        body: body.strip
      )
    end
  end
end
