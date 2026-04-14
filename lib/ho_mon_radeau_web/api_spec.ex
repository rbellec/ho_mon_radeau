defmodule HoMonRadeauWeb.ApiSpec do
  @moduledoc """
  OpenAPI specification for the HoMonRadeau admin API.
  """
  alias OpenApiSpex.{Info, OpenApi, Paths, SecurityScheme, Components}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      info: %Info{
        title: "HoMonRadeau Admin API",
        version: "1.0.0",
        description: "API REST d'administration pour l'événement HoMonRadeau / Tutto Blu."
      },
      paths: Paths.from_router(HoMonRadeauWeb.Router),
      components: %Components{
        securitySchemes: %{
          "bearer" => %SecurityScheme{
            type: "http",
            scheme: "bearer",
            description: "API token created from your profile page."
          }
        }
      },
      security: [%{"bearer" => []}]
    }
    |> OpenApiSpex.resolve_schema_modules()
  end
end
