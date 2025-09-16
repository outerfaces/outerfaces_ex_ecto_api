defmodule Mix.Tasks.OuterfacesEctoApiJsCodegen do
  use Mix.Task

  @shortdoc "Generates JSDoc types for api resources"

  @target_base_dir "outerfaces/projects/"
  @target_project_base "/tao_api_codegen/js/raw/"

  alias OuterfacesEctoApi.Codegen.JsCodegen

  @spec run(args :: list(String.t())) :: :ok
  def run(args \\ []) when is_list(args) do
    opts = parse_args(args)
    schema = Keyword.get(opts, :schema)

    schema_name =
      schema
      |> String.split(".")
      |> List.last()
      |> Macro.camelize()
      |> Macro.underscore()

    target_project_name = Keyword.get(opts, :target_project_name)
    controller_module = Keyword.get(opts, :controller_module)

    file_name =
      if controller_module != nil do
        formatted =
          controller_module
          |> String.split(".")
          |> List.last()
          |> Macro.camelize()
          |> Macro.underscore()

        "typedefs_#{schema_name}_#{formatted}.js"
      else
        "typedefs_#{schema_name}.js"
      end

    js_typedef =
      JsCodegen.generate_js_typedef(
        schema,
        controller_module
      )

    path = Path.join([@target_base_dir, target_project_name, @target_project_base])
    File.mkdir_p!(path)
    target_project_name = Path.join([path, file_name])
    File.write!(target_project_name, js_typedef)
  end

  defp parse_args(args) when is_list(args) do
    Enum.reduce(args, [], fn arg, acc ->
      [key, value] = String.split(arg, "=")
      [{String.to_atom(key), value} | acc]
    end)
  end
end
