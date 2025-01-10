# frozen_string_literal: true

require_relative "lib/datadog/loggers/version"

Gem::Specification.new do |spec|
  spec.name = "datadog-json_logger"
  spec.version = Datadog::Loggers::VERSION
  spec.authors = ["Eth3rnit3"]
  spec.email = ["eth3rnit3@gmail.com"]

  spec.summary = "Connect your ruby application to Datadog logging and tracing."
  spec.description = "This gem provides easy integration for connecting a ruby application to Datadog's logging and tracing services."
  spec.homepage = "https://github.com/buyco/datadog-json-logger"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  if ENV.fetch('GEM_PUSHER', 'default') == 'github'
    spec.metadata['allowed_push_host'] = 'https://rubygems.pkg.github.com/buyco'
  else
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  end


  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/buyco/datadog-json-logger"
  spec.metadata["changelog_uri"] = "https://github.com/buyco/datadog-json-logger/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(__dir__) do
      `git ls-files -z`.split("\x0").reject do |f|
        (File.expand_path(f) == __FILE__) ||
          f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
      end
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("datadog", ">= 2.8")

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
