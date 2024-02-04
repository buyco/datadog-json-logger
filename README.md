# Datadog::JSONLogger

[![CodeQL](https://github.com/buyco/datadog-json-logger/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/buyco/datadog-json-logger/actions/workflows/github-code-scanning/codeql)
[![Rubocop and Rspec](https://github.com/buyco/datadog-json-logger/actions/workflows/main.yml/badge.svg)](https://github.com/buyco/datadog-json-logger/actions/workflows/main.yml)
[![Publish on RubyGems](https://github.com/buyco/datadog-json-logger/actions/workflows/gem-push.yml/badge.svg)](https://github.com/buyco/datadog-json-logger/actions/workflows/gem-push.yml)

`Datadog::JSONLogger` is a Ruby gem designed to seamlessly integrate Ruby applications with Datadog's logging and tracing services. This gem allows your Ruby application to format its output as JSON, including necessary correlation IDs and other details for optimal Datadog functionality.

## Prerequisites

Before you begin, ensure you have [ddtrace](https://github.com/DataDog/dd-trace-rb) configured in your Ruby application, as `Datadog::JSONLogger` relies on `ddtrace` for tracing data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'datadog-json_logger'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install datadog-json_logger
```

## Usage

### JSONLogger

`Datadog::JSONLogger` can be easily integrated into your Ruby application. Here's a quick example of how to use it in a Sinatra application:

```ruby
# Example in Sinatra (app.rb)
require 'datadog/json_logger'

def logger
  @logger ||= Datadog::JSONLogger.new
end

set :logger, logger

Sinatra::Application.logger.info("hello")
# => {"dd":{"trace_id":"0","span_id":"0","env":null,"service":"console","version":null},"timestamp":"2023-11-22 22:28:00 +0100","severity":"INFO ","progname":"","message":"hello"}
```

#### Add Custom Keys
Create a custom formatter that inherits from `Datadog::Loggers::JSONFormatter` to add custom keys as shown below:

```ruby
class CustomFormatter < Datadog::Loggers::JSONFormatter
  def self.call(severity, datetime, progname, msg)
    super do |log_hash|
      log_hash[:my_custom_key] = "my_value"
      log_hash[:my_custom_hash] = { key: "value" }
    end
  end
end

def logger
  return @logger if @logger

  @logger = Datadog::JSONLogger.new
  @logger.progname = "my_app"
  @logger.formatter = CustomFormatter
  @logger
end

Sinatra::Application.logger.info("hello")
# {"dd":{"trace_id":"0","span_id":"0","env":null,"service":"console","version":null},"timestamp":"2023-11-22 22:46:01 +0100","severity":"INFO ","progname":"my_app","message":"hello","my_custom_key":"my_value","my_custom_hash":{"key":"value"}}
```

### SinatraMiddleware

`Datadog::SinatraMiddleware` formats Rack requests as JSON and disables the default textual stdout of `Rack::CommonLogger`:

```ruby
# Example in Sinatra (app.rb)
require 'datadog/sinatra_middleware'

use Datadog::SinatraMiddleware, logger
```

## Features
| Feature                 | Link                                            | Compatibility |
|-------------------------|-------------------------------------------------|---------------|
| JSON correlated logging | [Ruby Collection](https://docs.datadoghq.com/logs/log_collection/ruby/?tab=lograge) | ✅             |
| Tracing                 | [Ruby Tracing application](https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/ruby) | ✅             |
| Error Tracking          | [Datadog error tracking](https://www.datadoghq.com/product/error-tracking) | ✅             |


## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buyco/datadog-json-logger. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/buyco/datadog-json-logger/blob/main/CODE_OF_CONDUCT.md).

1. Fork the repository (https://github.com/buyco/datadog-json-logger/fork)
2. Create your feature branch (`git checkout -b feature/my_feature`)
3. Commit your changes (`git commit -am 'Add a new feature'`)
4. Push the branch (`git push origin feature/my_feature`)
5. Open a Pull Request

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Datadog::JSONLogger project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/buyco/datadog-json-logger/blob/main/CODE_OF_CONDUCT.md).