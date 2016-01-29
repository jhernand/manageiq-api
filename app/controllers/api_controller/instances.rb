class ApiController
  module Instances
    def terminate_resource_instances(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for terminating a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Terminating #{instance_ident(instance)}")
        terminate_instance(instance)
      end
    end

    def stop_resource_instances(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for stopping a #{type} resource" unless id

      api_action(type, id) do |klass|
        instance = resource_search(id, type, klass)
        api_log_info("Stopping #{instance_ident(instance)}")

        result = validate_instance_for_action(instance, "stop")
        result = stop_instance(instance) if result[:success]
        result
      end
    end

    private

    def instance_ident(instance)
      "Instance id:#{instance.id} name:'#{instance.name}'"
    end

    def terminate_instance(instance)
      desc = "#{instance_ident(instance)} terminating"
      task_id = queue_object_action(instance, desc, :method_name => "vm_destroy", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def stop_instance(instance)
      desc = "#{instance_ident(instance)} stopping"
      task_id = queue_object_action(instance, desc, :method_name => "stop", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def validate_instance_for_action(instance, action)
      validation = instance.send("validate_#{action}")
      action_result(validation[:available], validation[:message].to_s)
    end
  end
end