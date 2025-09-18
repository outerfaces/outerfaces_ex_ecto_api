defmodule OuterfacesEctoApi.Mix.JsCodegenHelpers do
  @moduledoc """
  Generates JSDoc types for api resources

  Example usage module:
  ```elixir
  defmodule Mix.Tasks.JSCodegenMyExampleProject do
    use Mix.Task

    @shortdoc "Generates js typedefs for the api resources for My Outerfaces Example Project"

    @project_name "my_example_project"

    def run(_args) do
      project_js_codegen_config() |> OuterfacesEctoApi.Mix.JsCodegenHelpers.run_js_codegen(@project_name)
    end

    def project_js_codegen_config do
      [
        %{
          schema: "MyApp.MyContext.MySchema"
        },
        %{
          schema: "MyApp.MyContext.MySchema",
          controller_name: "MyAppWeb.MyContext.MySchemaController"
        },
      ]
    end
  ```
  """

  @spec run_js_codegen(schema_configurations :: list(map()), project_name :: String.t()) :: :ok
  def run_js_codegen(schema_configurations, project_name) do
    schema_configurations |> Enum.each(&run_for_schema(&1, project_name))

    raw_path = Path.join(["outerfaces/projects/", project_name, "_api_codegen/js/raw"])
    IO.puts("Reading files from: #{raw_path}")

    files = Path.wildcard(Path.join([raw_path, "*"]))
    IO.inspect(files, label: "Files found")

    base_typedefs = base_js_typedefs()

    combined =
      files
      |> Enum.reduce(base_typedefs, fn file, acc ->
        file_contents = File.read!(file)
        acc <> "\n" <> file_contents
      end)

    output_dir = Path.join(["outerfaces/projects/", project_name, "_api_codegen/js/output"])
    File.mkdir_p!(output_dir)
    output_path = Path.join([output_dir, "typedefs.js"])

    if File.exists?(output_path) do
      File.rm!(output_path)
    end

    File.write!(output_path, combined)
    File.rm_rf!(raw_path)
    IO.puts("Combined typedefs written to: #{output_path}")
  end

  @spec base_js_typedefs :: String.t()
  def base_js_typedefs do
    """
    export {};

    /**
      * @typedef {Object} PageInfo
      * @property {number} limit
      * @property {number} offset
      * @property {number} total_count
      * @property {number} total_pages
      * @property {boolean} has_next_page
      * @property {boolean} has_previous_page
      */

      /**
      * @typedef {Object} ResourceQueryOptions
      * @property {number} [timeout]
      */

      /**
      * @template Q - The type result for fetchOne
      * @template R - The type of the query for fetchMany
      * @template S - The type of the result for fetchMany
      * @template [T=undefined] - The type of the data for create
      * @template [U=undefined] - The type of the result for create
      * @template [V=undefined] - The type of the data for update
      * @template [W=undefined] - The type of the result for update
      * @typedef {Object} ResourceServiceMethods
      * @property {(id: number, options?: ResourceQueryOptions) => Promise<Q | null>} fetchOne
      * @property {(query: R, options?: ResourceQueryOptions) => Promise<S>} fetchMany
      * @property {(data: T, options?: ResourceQueryOptions) => Promise<U>} create
      * @property {(id: number, data: V, options?: ResourceQueryOptions) => Promise<W>} update
      * @property {(pathFragment: string, method: string, data?: any, options?: ResourceQueryOptions) => Promise<any>} customRequest
      */
    """
  end

  def run_for_schema(%{schema: schema, controller_name: controller_name}, project_name)
      when is_binary(schema) and is_binary(controller_name) and is_binary(project_name) do
    Mix.Task.reenable("outerfaces_ecto_api.js_codegen")

    Mix.Task.run("outerfaces_ecto_api.js_codegen", [
      "schema=#{schema}",
      "target_project_name=#{project_name}",
      "controller_module=#{controller_name}"
    ])
  end

  def run_for_schema(%{schema: schema}, project_name)
      when is_binary(schema) and
             is_binary(project_name) do
    Mix.Task.reenable("outerfaces_ecto_api.js_codegen")

    Mix.Task.run("outerfaces_ecto_api.js_codegen", [
      "schema=#{schema}",
      "target_project_name=#{project_name}"
    ])
  end
end
