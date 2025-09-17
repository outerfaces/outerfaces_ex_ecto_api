defmodule JsCodegenTest do
  use ExUnit.Case

  defmodule Thing do
    use Ecto.Schema

    schema "things" do
      field(:name, :string)
      field(:is_primary, :boolean, default: false)
      belongs_to(:disposition, OuterfacesEctoApiTest.Disposition)
      timestamps()
    end
  end

  defmodule TestSchemaOne do
    use Ecto.Schema

    schema "test_schema_ones" do
      field(:name, :string)
      field(:value, :integer)
      field(:archived_at, :utc_datetime)
      belongs_to(:thing, OuterfacesEctoApiTest.Thing)
      belongs_to(:other_thing, OuterfacesEctoApiTest.Thing)
      timestamps()
    end
  end

  test "generate jsdoc for a schema" do
    jsdoc =
      OuterfacesEctoApi.Codegen.JsCodegen.generate_js_typedef("JsCodegenTest.TestSchemaOne", nil)

    assert jsdoc ==
             """
             /**
              * @typedef {Object} TestSchemaOne
              * @property {number} id
              * @property {string} name
              * @property {number} value
              * @property {string} archived_at
              * @property {number} thing_id
              * @property {number} other_thing_id
              * @property {string} inserted_at
              * @property {string} updated_at
              * @property {Thing | null} thing
              * @property {Thing | null} other_thing
              */
             """
  end

  defmodule TestSchemaTwo do
    use Ecto.Schema

    def serializer_skip_fields(_opts), do: [:internal_field]

    schema "test_schema_twos" do
      field(:title, :string)
      field(:description, :string)
      field(:is_active, :boolean)
      field(:internal_field, :string)
      has_many(:ones, JsCodegenTest.TestSchemaOne)
      has_one(:ones_primary_thing, through: [:ones, :thing], where: [is_primary: true])
      timestamps()
    end
  end

  test "with skipped fields" do
    jsdoc =
      OuterfacesEctoApi.Codegen.JsCodegen.generate_js_typedef("JsCodegenTest.TestSchemaTwo", nil)

    assert jsdoc ==
             """
             /**
              * @typedef {Object} TestSchemaTwo
              * @property {number} id
              * @property {string} title
              * @property {string} description
              * @property {boolean} is_active
              * @property {string} inserted_at
              * @property {string} updated_at
              * @property {TestSchemaOne[] | null} ones
              * @property {Thing | null} ones_primary_thing
              */
             """
  end

  defmodule TestController do
    def index_preloads(), do: [:thing]
    def show_preloads(), do: [{:thing, [:disposition]}, :other_thing]
  end

  test "with a controller" do
    jsdoc =
      OuterfacesEctoApi.Codegen.JsCodegen.generate_js_typedef(
        "JsCodegenTest.TestSchemaOne",
        "JsCodegenTest.TestController"
      )

    assert jsdoc ==
             """
             /**
              * @typedef {Object} TestSchemaOneIndexData
              * @property {number} id
              * @property {string} name
              * @property {number} value
              * @property {string} archived_at
              * @property {number} thing_id
              * @property {number} other_thing_id
              * @property {string} inserted_at
              * @property {string} updated_at
              * @property {Thing | null} thing
              */

             /**
              * @typedef {Object} FetchTestSchemaOneIndexQueryParams
              * @property {Object} [filters] - Filters to apply to the query
              * @property {string[]} [sort] - Sort order for the query. Format: ['sort_name:asc', 'sort_name:desc']
              * @property {number} [limit] - Maximum number of records to return
              * @property {number} [offset] - Offset for the query
              *
             */

             /**
              * @typedef {Object} FetchTestSchemaOneIndexQueryResult
              * @property {number} status,
              * @property {Object} results
              * @property {TestSchemaOneIndexData[]} results.data
              * @property {string} results.schema
              * @property {PageInfo} results.page_info
              */

             /**
              * @typedef {Object} TestSchemaOneShowData
              * @property {number} id
              * @property {string} name
              * @property {number} value
              * @property {string} archived_at
              * @property {number} thing_id
              * @property {number} other_thing_id
              * @property {string} inserted_at
              * @property {string} updated_at
              * @property {Thing | null} thing
              * @property {Thing | null} other_thing
              */

             /**
              * @typedef {Object} FetchTestSchemaOneShowQueryResult
              * @property {number} status
              * @property {Object} results
              * @property {TestSchemaOneShowData} results.data
              * @property {string} results.schema
              */
             """
  end
end
