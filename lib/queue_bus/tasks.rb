# require 'queue_bus/tasks'
# will give you these tasks

namespace :queuebus do

  desc "Subscribes this application to QueueBus events"
  task :subscribe => [ :preload ] do
    manager = ::QueueBus::TaskManager.new(true)
    count = manager.subscribe!
    raise "No subscriptions created" if count == 0
  end

  desc "Unsubscribes this application from QueueBus events"
  task :unsubscribe => [ :preload ] do
    manager = ::QueueBus::TaskManager.new(true)
    count = manager.unsubscribe!
    puts "No subscriptions unsubscribed" if count == 0
  end

  desc "List QueueBus queues that need worked"
  task :queues => [ :preload ] do
    manager = ::QueueBus::TaskManager.new(false)
    queues = manager.queue_names + ['bus_incoming']
    puts queues.join(", ")
  end

  desc "list time based subscriptions"
  task :list_scheduled => [ :preload ] do
    scheduled_list = QueueBus::Application.all.flat_map do |app|
      app.send(:subscriptions).all
        .select { |s| s.matcher.filters['bus_event_type'] == 'heartbeat_minutes'  }
    end
    scheduled_text_list = scheduled_list.collect { |e| [ e.key, e.matcher.filters['hour'] || "*", e.matcher.filters['minute'] || "*" ] }
    puts 'key, hour, minute'
    puts scheduled_text_list.sort_by { |(_, hour, minute)| [hour.to_i, minute.to_i] }.map(&:to_csv)
  end

  # Preload app files if this is Rails
  # you can also do this to load the right things
  task :preload do
    require 'queue-bus'
  end
end
