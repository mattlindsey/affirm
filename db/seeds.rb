# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create sample affirmations
affirmations = [
"Today I will honor my own values.",
"It is exciting to know that I am in charge.",
"I am learning new ways to deal with all that comes up in my life today.",
"Today I am learning to be gentle with myself.",
"Today I am becoming more aware that I can choose how I feel in the moment.",
"Today I am going to spend more time looking for all the positive things about myself.",
"Today I recognize and acknowledge myself as a terrific human being.",
"Today I release all thoughts and feelings that cause me harm.",
"Today I am beginning to experience all that I am, a unique human being.",
"I have all the strength I need today and accept the realities in my life.",
"Today I have all the courage I need to take a step forward in my life. I can manage one step at a time, one change at a time, with ease and with confidence.",
"I deserve to feel good about myself today and I am learning how.",
"Today I am doing everything I can to accept me as I am.",
"Today I am stretching myself and taking new risks.",
"Today I know I have done the best that I can.",
"I am learning to trust the positive and loving people in my life today.",
"I am filled with all the strength and energy I need today to follow my own truth.",
"Today I am doing everything I can to be in the now.",
"Every step I take today makes me better and better.",
"Today I have the courage to let go of all that is holding me back.",
"I am putting a large stop sign to all my negative self-talk today.",
"Change is an action step and I am taking new action today to bring positive changes to my life.",
"I am willing to do all I am able to do to be the best of who I am.",
"I celebrate myself today. I am alive. I am growing.",
"I have all the power I need to today to say no to negative choices.",
"Today I will look for opportunities to continue to grow through seeing the beauty around me and in me.",
"I am open to being fully alive and enjoying adventure.",
"Today I choose to accept life on its terms… all of them.",
"Today I choose to think positive thoughts.",
"It is beautiful to know that I am the creator of the way I think and feel today, that I can choose my now.",
"Today I am open to making small changes in my life that lead me, a step at a time, on my path to recovery.",
"Today I am bringing awareness to my self-talk and replacing all negative thoughts with positive thoughts as soon as they appear.",
"I am willing to take chances to grow and risk and feel what it means to be fully alive in the moment.",
"Today I have the courage to face life as it is and make progress a part of my life.",
"Today I will be aware not to judge myself when I act “less than perfect”.",
"I can handle anything that comes up today… even if it is only for a moment at a time.",
"I will open myself up to all the possibilities around me today, leaving my fear of change behind.",
"Today I will feel good about myself and accept myself just the way I am.",
"I won't always feel this way."
]

affirmations.each do |content|
  Affirmation.find_or_create_by!(content: content)
end
