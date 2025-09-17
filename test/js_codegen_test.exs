defmodule JsCodegenTest do
  use ExUnit.Case

  defmodule TestSchemaOne do
    use Ecto.Schema

    schema "test_schema_ones" do
      field(:name, :string)
      field(:value, :integer)
      field(:archived_at, :utc_datetime)
      belongs_to(:thing, OuterfacesEctoApiTest.Thing)
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
              * @property {string} inserted_at
              * @property {string} updated_at
              * @property {Thing | null} thing
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
end
