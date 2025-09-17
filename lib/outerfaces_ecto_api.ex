defmodule OuterfacesEctoApi do
  @moduledoc """
  Documentation for `OuterfacesEctoApi`.
  """

  defdelegate all(
                repo,
                schema,
                preloads,
                filter_specs,
                sort_specs,
                params,
                opts \\ []
              ),
              to: OuterfacesEctoApi.QueryEngine

  defdelegate build(
                schema,
                filters,
                params,
                opts \\ []
              ),
              to: OuterfacesEctoApi.QueryEngine

  defdelegate get(
                repo,
                schema,
                id,
                preloads,
                opts \\ []
              ),
              to: OuterfacesEctoApi.QueryEngine

  defdelegate to_jsdoc(
                schema,
                controller_module \\ nil
              ),
              to: OuterfacesEctoApi.Codegen.JsCodegen,
              as: :generate_js_typedef
end
