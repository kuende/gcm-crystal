class GCM
  class Config
    macro field(attr, class_type, default_value)
      @{{attr.id}} = {{default_value}}

      def {{attr.id}} : {{class_type}}
        @{{attr.id}}
      end

      def {{attr.id}}=(value : {{class_type}})
        @{{attr.id}} = value
      end
    end

    field :username, String, ""
    field :password, String, ""
    field :read_timeout, Int, 60
  end
end
