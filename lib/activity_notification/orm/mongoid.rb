module ActivityNotification
  module Association
    extend ActiveSupport::Concern

    class_methods do
      # Defines has_many association with ActivityNotification models.
      # @return [Mongoid::Criteria<Object>] Database query of associated model instances
      def has_many_records(name, options = {})
        has_many_polymorphic_xdb_records name, options
      end

      # Defines polymorphic belongs_to association with models in other database.
      def belongs_to_polymorphic_xdb_record(name, _options = {})
        association_name     = name.to_s.singularize.underscore
        id_field, type_field = "#{association_name}_id", "#{association_name}_type"
        field id_field,   type: String
        field type_field, type: String

        self.instance_eval do
          define_method(name) do |reload = false|
            reload and self.instance_variable_set("@#{name}", nil)
            if self.instance_variable_get("@#{name}").blank?
              if (class_name = self.send(type_field)).present?
                object_class = class_name.classify.constantize
                self.instance_variable_set("@#{name}", object_class.where(id: self.send(id_field)).first)
              end
            end
            self.instance_variable_get("@#{name}")
          end

          define_method("#{name}=") do |new_instance|
            if new_instance.nil? then instance_id, instance_type = nil, nil else instance_id, instance_type = new_instance.id, new_instance.class.name end
            self.send("#{id_field}=", instance_id)
            self.send("#{type_field}=", instance_type)
            self.instance_variable_set("@#{name}", nil)
          end
        end
      end

      # Defines polymorphic has_many association with models in other database.
      # @todo Add dependent option
      def has_many_polymorphic_xdb_records(name, options = {})
        association_name     = options[:as] || name.to_s.underscore
        id_field, type_field = "#{association_name}_id", "#{association_name}_type"
        object_name          = options[:class_name] || name.to_s.singularize.camelize
        object_class         = object_name.classify.constantize

        self.instance_eval do
          define_method(name) do |reload = false|
            reload and self.instance_variable_set("@#{name}", nil)
            if self.instance_variable_get("@#{name}").blank?
              self.instance_variable_set("@#{name}", object_class.where(id_field => self.id, type_field => self.class.name))
            end
            self.instance_variable_get("@#{name}")
          end
        end
      end
    end
  end
end

require_relative 'mongoid/notification.rb'
require_relative 'mongoid/subscription.rb'
