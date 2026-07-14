# frozen_string_literal: true

require_relative "../errors"

class TCGdex
  # Superclass of every model. Subclasses declare their fields with {.attribute};
  # instances are built from a parsed JSON Hash.
  #
  # Models are tolerant by design: unknown JSON keys are ignored rather than raising
  # (the API ships fields faster than SDKs model them), and missing keys read as nil.
  # Nothing is lost — {#to_h} always returns the raw parsed Hash.
  #
  # @example Declaring a model
  #   class Card < BaseModel
  #     attribute :local_id                             # reads the JSON key "localId"
  #     attribute :set, model: SetBrief                 # casts a nested Hash
  #     attribute :attacks, model: CardAttack, array: true
  #     attribute :variants_detailed, key: "variants_detailed"  # key isn't camelCase
  #   end
  class BaseModel
    QUALITIES = %w[high low].freeze
    EXTENSIONS = %w[png jpg webp].freeze

    class << self
      # Declares a field.
      #
      # @param name [Symbol] the Ruby attribute name; the JSON key is its camelCase
      #   form ("local_id" → "localId") unless +key+ says otherwise
      # @param key [String, nil] the JSON key, when it isn't the camelCase of +name+
      # @param model [Class, nil] a BaseModel subclass to cast the value into
      # @param array [Boolean] cast each element rather than the value itself
      # @return [void]
      def attribute(name, key: nil, model: nil, array: false)
        attributes[name.to_sym] = { key: key || camelize(name), model: model, array: array }
        attr_reader(name)
      end

      # @return [Hash{Symbol => Hash}] declared fields, including inherited ones
      def attributes
        @attributes ||= superclass.respond_to?(:attributes) ? superclass.attributes.dup : {}
      end

      private

      # The camelCase mapping is mechanical by convention, so this stays dumb.
      def camelize(name)
        name.to_s.gsub(/_([a-z])/) { Regexp.last_match(1).upcase }
      end
    end

    # @return [TCGdex, nil] the client this model came from; relationship helpers
    #   (#full_card, #full_set, …) need it
    attr_reader :client

    # @param data [Hash, nil] a parsed JSON object
    # @param client [TCGdex, nil] the client to attach, for relationship helpers
    def initialize(data, client: nil)
      @data = data || {}
      @client = client

      self.class.attributes.each do |name, options|
        instance_variable_set(:"@#{name}", cast(@data[options[:key]], options))
      end
    end

    # @return [Hash] the raw parsed JSON, including keys this SDK does not model
    def to_h
      @data
    end

    # Two models are equal when they are the same class and carry the same raw data.
    def ==(other)
      other.class == self.class && other.to_h == to_h
    end
    alias eql? ==

    def hash
      [self.class, @data].hash
    end

    # Card hashes are huge; identify the model without spamming the console.
    def inspect
      label = @data["id"] || @data["name"]
      "#<#{self.class.name}#{" #{label.inspect}" if label}>"
    end

    private

    def cast(value, options)
      model = options[:model]
      return value if value.nil? || model.nil?

      if options[:array]
        return nil unless value.is_a?(Array)

        value.map { |item| model.new(item, client: client) }
      else
        model.new(value, client: client)
      end
    end

    # Card images carry a quality; every other asset (logos, symbols) does not.
    def image_asset_url(base, quality, extension)
      quality = validate!(quality, QUALITIES, "quality")
      extension = validate!(extension, EXTENSIONS, "extension")

      "#{base}/#{quality}.#{extension}" unless base.nil?
    end

    def asset_url(base, extension)
      extension = validate!(extension, EXTENSIONS, "extension")

      "#{base}.#{extension}" unless base.nil?
    end

    # Validate before the nil check, so a typo raises even for an asset-less model.
    def validate!(value, allowed, label)
      string = value.to_s.downcase
      return string if allowed.include?(string)

      raise ArgumentError, "#{label} must be one of #{allowed.join(", ")} (got #{value.inspect})"
    end

    def client!
      client || raise(Error, "model is not attached to a TCGdex client")
    end
  end
end
