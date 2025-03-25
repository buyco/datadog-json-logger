# Datadog::JSONLogger

[![CodeQL](https://github.com/buyco/datadog-json-logger/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/buyco/datadog-json-logger/actions/workflows/github-code-scanning/codeql)
[![Rubocop and Rspec](https://github.com/buyco/datadog-json-logger/actions/workflows/main.yml/badge.svg)](https://github.com/buyco/datadog-json-logger/actions/workflows/main.yml)
[![Publish on RubyGems](https://github.com/buyco/datadog-json-logger/actions/workflows/gem-push.yml/badge.svg)](https://github.com/buyco/datadog-json-logger/actions/workflows/gem-push.yml)

## Overview

`Datadog::JSONLogger` is a Ruby gem that provides seamless integration with Datadog's logging and tracing services. It formats logs as JSON with correlation IDs, making it easy to integrate with Datadog's log management and APM services.

## Features

| Feature                 | Description | Status |
|-------------------------|-------------|---------|
| JSON correlated logging | Formats logs as JSON with Datadog correlation IDs for better log analysis | ✅ |
| Tracing                 | Integrates with Datadog APM for distributed tracing | ✅ |
| Error Tracking          | Compatible with Datadog error tracking | ✅ |
| Rack Middleware         | Provides a Rack middleware for HTTP request logging | ✅ |
| Bunny Integration       | Adds tracing for RabbitMQ operations via Bunny | ✅ |

## Requirements

- Ruby 3.0+
- [ddtrace](https://github.com/DataDog/dd-trace-rb) properly configured in your application

## Installation

Add to your application's Gemfile:

```ruby
gem 'datadog-json_logger'
```

And run:

```bash
bundle install
```

Or install it directly:

```bash
gem install datadog-json_logger
```

## Usage

### Basic JSON Logger

```ruby
require 'datadog/json_logger'

# Create a logger instance
logger = Datadog::JSONLogger.new
logger.info('Hello World')
# => {"dd":{"trace_id":"0","span_id":"0","env":null,"service":"console","version":null},"timestamp":"2023-11-22 22:28:00 +0100","severity":"INFO ","progname":"","message":"Hello World"}
```

### Configuration

```ruby
Datadog::JSONLogger.configure do |config|
  # Function to extract current user from environment
  config.current_user = ->(env) { { email: env['current_user']&.email } }
  
  # Custom environment keys
  config.controller_key = "sinatra.controller_name"
  config.resource_key = "sinatra.resource_name"
  config.action_key = "sinatra.action_name"
  
  # Custom context for all logs
  config.custom_context = -> { { environment: ENV['RACK_ENV'] } }
end
```

### With Rails

In your `config/initializers/datadog.rb`:

```ruby
require 'datadog/json_logger'

Datadog::JSONLogger.configure do |config|
  config.current_user = ->(env) { { email: env['warden']&.user&.email } } 
  config.controller_key = "action_controller.instance"
  config.action_key = "action_dispatch.request.path_parameters[:action]"
  config.resource_key = "action_dispatch.request.path_parameters[:controller]"
end

# Configure Rails logger
Rails.application.config.logger = Datadog::JSONLogger.new
```

### With Sinatra

```ruby
require 'datadog/json_logger'
require 'datadog/rack_middleware'

class MyApp < Sinatra::Base
  configure do
    # Configure Datadog logger
    Datadog::JSONLogger.configure do |config|
      config.current_user = ->(env) { { email: env['warden']&.user&.email } }
    end
    
    # Set up logger
    set :logger, Datadog::JSONLogger.new
    
    # Add Rack middleware
    use Datadog::RackMiddleware, settings.logger
  end
  
  # Your routes here
end
```

### Custom Formatter

Create a custom formatter to add more fields to your logs:

```ruby
class CustomFormatter < Datadog::Loggers::JSONFormatter
  def self.call(severity, datetime, progname, msg)
    super do |log_hash|
      log_hash[:app_name] = "my_application"
      log_hash[:environment] = ENV['RACK_ENV']
      log_hash[:custom_field] = "custom value"
    end
  end
end

# Use the custom formatter
logger = Datadog::JSONLogger.new
logger.formatter = CustomFormatter
```

### Rack Middleware

The `Datadog::RackMiddleware` logs HTTP requests in a structured format and disables the default `Rack::CommonLogger` output:

```ruby
require 'datadog/rack_middleware'

# For Rack applications
use Datadog::RackMiddleware, logger

# For Rails
Rails.application.config.middleware.use Datadog::RackMiddleware, Rails.logger
```

Sample output:

```json
{
  "dd": {
    "trace_id": "1234567890",
    "span_id": "0987654321",
    "env": "production",
    "service": "my-service",
    "version": "1.0.0"
  },
  "request": true,
  "params": {"q": "search"},
  "status": 200,
  "format": "application/json",
  "duration": 45,
  "request_ip": "127.0.0.1",
  "method": "GET",
  "path": "/api/users",
  "controller": "UsersController",
  "action": "index",
  "resource": "users",
  "usr": {"email": "user@example.com"},
  "message": "Received GET request from 127.0.0.1 at /api/users Responded with status 200 in 45ms."
}
```

### Bunny Integration

Trace RabbitMQ operations with the Bunny integration:

```ruby
require 'datadog/json_logger'

# Configure Datadog tracing
Datadog.configure do |c|
  c.tracing.instrument :bunny, service_name: 'rabbitmq-service'
  # Other Datadog configurations...
end
```

#### End-to-End Tracing for Bunny Consumers

For complete end-to-end tracing when consuming messages with Bunny, you need to manually continue the trace by using the helper in `lib/datadog/tracing/contrib/bunny/utils.rb`. Since the `on_delivery` method is a block, it's not possible to automatically retrieve trace information to continue the trace.

```ruby
require 'datadog/tracing/contrib/bunny/utils'

# Use Bunny as normal
bunny = Bunny.new
bunny.start

channel = bunny.create_channel
queue = channel.queue("my_queue")

# Publishing (automatically traced)
channel.default_exchange.publish("Hello World!", routing_key: queue.name)

# Consuming (automatically traced)
queue.subscribe(block: true) do |delivery_info, properties, payload|
  # Continue the trace from the producer
  if properties.headers && properties.headers[:trace_digest]
    Datadog::Tracing::Contrib::Bunny::Utils.continue_trace!(properties.headers[:trace_digest])
  end

  handle_message(payload)
end
```

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
