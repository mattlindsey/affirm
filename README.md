# Affirmations README

This project is for learning purposes and can be used to see positive daily Affirmations, record Gratifications, and record mood.

# Contributing

See [CONTRIBUTING.md](https://github.com/mattlindsey/affirm/blob/main/CONTRIBUTING.md).

Working with this project is a good way to learn Ruby on Rails and AI LLMs (Large Language Models)!

# Setting Up for Development

These are the steps for setting up your development environment locally.

### Step 1: Get your own local copy of the project to work on

You'll do your development work on your own forked copy of the project, so hit the 'clone' button in github.

#### Keeping a fork up to date

1. Clone your fork:

   ```bash
   git clone git@github.com:YOUR-USERNAME/YOUR-FORKED-REPO.git
   ```

2. Add remote from original repository in your forked repository:

   ```bash
   cd into/cloned/fork-repo
   git remote add upstream https://github.com/mattlindsey/affirm.git
   git fetch upstream
   ```

3. Updating your fork frequently from original repo to keep it up to date

   ```bash
   git pull upstream main
   ```

### Step 2: Install the gems with `bundle install`

```bash
bundle install
```

### Step 3: Set up the database and seed data

Run these commands;

```bash
bin/rails db:setup
bin/rails db:seed
```

### Step 4: Run the tests

Now you're ready to run the tests:

```bash
bin/rails test
```

### Step 5: To use AI features set your OpenAI key using export (do NOT put the keys directly in your code!)

```bash
export OPENAI_API_KEY=sk-key
```

### Step 6. Start the server

```bash
bin/dev
```

You can now see the system working [locally](http://localhost:3000)

## Code Style

Before committing your code, ensure that it follows ruby and rails style standards

```bash
bundle exec rubocop
bundle exec rubocop -A  (to auto fix any problems)
```

We recommend following the [Ruby Style Guide](https://github.com/rubocop-hq/ruby-style-guide)
