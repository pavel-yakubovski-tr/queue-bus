# frozen_string_literal: true

module QueueBus
  # Fans out an event to multiple queues
  #
  # When a single event is broadcast, it may have zero to many subscriptions attached to it.
  # The Driver is what is run in order to look up the subscription matches and enqueue each
  # of the jobs. It uses the class_name supplied by the subscription to know which class will
  # be performed.
  class Driver
    class << self
      def subscription_matches(attributes)
        out = []
        Application.all.each do |app|
          subs = app.subscription_matches(attributes)
          out.concat(subs)
        end
        out
      end

      def perform(attributes = {})
        raise 'No attributes passed' if attributes.empty?

        ::QueueBus.log_worker("Driver running: #{attributes.inspect}")

        subscription_matches(attributes).each do |sub|
          ::QueueBus.log_worker("  ...sending to #{sub.queue_name} queue with class #{sub.class_name} for app #{sub.app_key} because of subscription: #{sub.key}")

          bus_attr = {  'bus_driven_at' => Time.now.to_i,
                        'bus_rider_queue' => sub.queue_name,
                        'bus_rider_app_key' => sub.app_key,
                        'bus_rider_sub_key' => sub.key,
                        'bus_rider_class_name' => sub.class_name }
          bus_attr = bus_attr.merge(attributes || {})
          ::QueueBus.enqueue_to(sub.queue_name, sub.class_name, bus_attr)
        end
      end
    end
  end
end
