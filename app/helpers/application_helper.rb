module ApplicationHelper
  # Builds an array of breadcrumb items based on the current request path.
  # Each item is a hash with :name and :path. The last item represents
  # the current page and may be rendered without a link.
  def breadcrumbs
    return [] if request.path == "/"

    segments = request.path.sub(/^\//, "").split("/")
    accumulated_path = ""

    items = [ { name: "Home", path: root_path } ]

    segments.each_with_index do |segment, index|
      accumulated_path += "/#{segment}"

      # Humanize the segment for display
      display_name = segment.tr("_-", " ").titleize

      items << { name: display_name, path: accumulated_path }
    end

    items
  end
end
