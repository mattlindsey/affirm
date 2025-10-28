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

  # JavaScript for mood slider interaction
  def mood_slider_script
    javascript_tag do
      <<~JAVASCRIPT.html_safe
        // Localize greeting using browser time
        const timeGreetingElement = document.getElementById("time-greeting");
        if (timeGreetingElement) {
          const localHour = new Date().getHours();
          let localizedGreeting;

          if (localHour >= 5 && localHour <= 11) {
            localizedGreeting = "Good morning!";
          } else if (localHour >= 12 && localHour <= 17) {
            localizedGreeting = "Good afternoon!";
          } else if (localHour >= 18 && localHour <= 22) {
            localizedGreeting = "Good evening!";
          } else {
            localizedGreeting = "Good night!";
          }

          timeGreetingElement.textContent = localizedGreeting;
        }

        // Mood slider interaction
        const slider = document.getElementById('mood-slider');
        const emoji = document.getElementById('mood-emoji');
        const description = document.getElementById('mood-description');

        const moodData = {
          1: { emoji: '😢', description: 'Having a tough time' },
          2: { emoji: '😢', description: 'Having a tough time' },
          3: { emoji: '😔', description: 'Feeling low' },
          4: { emoji: '😔', description: 'Feeling low' },
          5: { emoji: '😐', description: 'Neutral' },
          6: { emoji: '😐', description: 'Neutral' },
          7: { emoji: '😊', description: 'Feeling good' },
          8: { emoji: '😊', description: 'Feeling good' },
          9: { emoji: '😄', description: 'Feeling amazing' },
          10: { emoji: '😄', description: 'Feeling amazing' }
        };

        function updateMoodDisplay() {
          const value = parseInt(slider.value);
          const mood = moodData[value];
          emoji.textContent = mood.emoji;
          description.textContent = mood.description;
        }

        slider.addEventListener('input', updateMoodDisplay);

        // Initialize display
        updateMoodDisplay();
      JAVASCRIPT
    end
  end
end
