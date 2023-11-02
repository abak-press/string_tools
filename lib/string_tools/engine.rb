# frozen_string_literal: true

module StringTools
  class Engine < ::Rails::Engine
    config.autoload_paths += Dir[config.root.join('lib')]

    initializer :string_tools, before: :load_init_rb do |app|
      app.config.string_tools = {
        css_sanitize: {properties: Sanitize::Config::RELAXED[:css][:properties]},
      }
    end
  end
end

