defmodule JsCodegenTest do
  use ExUnit.Case

  defmodule TestSchemaOne do
    use Ecto.Schema

    schema "test_schema_ones" do
      field(:name, :string)
      field(:value, :integer)
      field(:archived_at, :utc_datetime)
      belongs_to(:user, OuterfacesEctoApiTest.User)
      has_many(:things, OuterfacesEctoApiTest.Thing)
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
              * @property {number} user_id
              * @property {string} inserted_at
              * @property {string} updated_at
              * @property {User | null} user
              * @property {Thing[] | null} things
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

              */
             """
  end
end
