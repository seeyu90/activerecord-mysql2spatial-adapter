module ActiveModel
  module Type
    class Spatial < Value # :nodoc:
      def type
        :spatial
      end

      def spatial?
        type == :spatial
      end

      def klass
        type == :spatial ? ::RGeo::Feature::Geometry : super
      end

      private

      def cast_value(value)
        spatial_store = RGeo::ActiveRecord::SpatialFactoryStore.instance
        case value
          when ::RGeo::Feature::Geometry
            factory = spatial_store.factory(srid: value.srid)
            ::RGeo::Feature.cast(value, factory) rescue nil
          when ::String
            marker = value[4,1]
            if marker == "\x00" || marker == "\x01"
              factory = spatial_store.factory(srid: value[0,4].unpack(marker == "\x01" ? 'V' : 'N').first)
              ::RGeo::WKRep::WKBParser.new(factory).parse(value[4..-1]) rescue nil
            elsif value[0,10] =~ /[0-9a-fA-F]{8}0[01]/
              srid = value[0,8].to_i(16)
              if value[9,1] == '1'
                srid = [srid].pack('V').unpack('N').first
              end
              factory = spatial_store.factory(srid: srid)
              ::RGeo::WKRep::WKBParser.new(factory).parse(value[8..-1]) rescue nil
            else
              factory = spatial_store.factory
              ::RGeo::WKRep::WKTParser.new(factory, support_ewkt: true).parse(value) rescue nil
            end
          else
            nil
        end
      end
    end
  end
end
