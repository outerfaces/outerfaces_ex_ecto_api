defmodule QueryEngineTest do
  @doc """
  These tests for the QueryEngine module (though intentionally fragile by using `inspect`)
  are for demonstration purposes to show how the QueryEngine can be used
  to build Ecto queries with filtering and sorting capabilities.

  These tests do not require a database connection and focus on the query construction logic.

  The assertions use strings that are human readable rather than the AST,
  in order to show the intended query structure more clearly.
  """
  use ExUnit.Case

  alias OuterfacesEctoApi.QueryEngine
  alias OuterfacesEctoApi.QueryEngine.QueryFilter
  alias OuterfacesEctoApi.QueryEngine.QuerySort

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)
      timestamps()
    end
  end

  defmodule TestSchemaOne do
    use Ecto.Schema

    schema "test_schema_ones" do
      field(:name, :string)
      field(:value, :integer)
      field(:archived_at, :utc_datetime)
      belongs_to(:user, QueryEngineTest.User)
      belongs_to(:backup_user, QueryEngineTest.User)
      timestamps()
    end
  end

  test "build" do
    filter_specs = [
      {
        :is_active,
        {
          QueryFilter,
          :by_field,
          :archived_at,
          {:is_nil, :not_nil},
          _filter_with_nil_values = false,
          _fallback_value = true
        }
      }
    ]

    built_archived_query =
      QueryEngine.build(
        TestSchemaOne,
        filter_specs,
        %{"filters" => %{"is_active" => false}},
        _opts = []
      )

    built_active_query =
      QueryEngine.build(
        TestSchemaOne,
        filter_specs,
        %{"filters" => %{"is_active" => true}},
        _opts = []
      )

    assert built_archived_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, where: not is_nil(t0.archived_at)>}"

    assert built_active_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, where: is_nil(t0.archived_at)>}"
  end

  test "build with association filtering" do
    filter_specs = [
      user_name: {
        QueryFilter,
        :by_association_field,
        [:user],
        :name,
        :==,
        _filter_with_nil_values = false,
        _fallback_value = nil
      }
    ]

    built_query =
      QueryEngine.build(
        TestSchemaOne,
        filter_specs,
        %{"filters" => %{"user_name" => "Alice"}},
        _opts = []
      )

    assert built_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, left_join: u1 in QueryEngineTest.User, as: :user, on: t0.user_id == u1.id, where: u1.name == ^\"Alice\">}"
  end

  test "with multiple filters using the same association" do
    filter_specs = [
      user_name: {
        QueryFilter,
        :by_association_field,
        [:user],
        :name,
        :==,
        _filter_with_nil_values = false,
        _fallback_value = nil
      },
      user_id: {
        QueryFilter,
        :by_association_field,
        [:user],
        :id,
        :==,
        _filter_with_nil_values = false,
        _fallback_value = nil
      }
    ]

    built_query =
      QueryEngine.build(
        TestSchemaOne,
        filter_specs,
        %{"filters" => %{"user_name" => "Alice", "user_id" => 1}},
        _opts = []
      )

    assert built_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, left_join: u1 in QueryEngineTest.User, as: :user, on: t0.user_id == u1.id, where: u1.id == ^1, where: u1.name == ^\"Alice\">}"
  end

  test "with multiple filters using different associations" do
    filter_specs = [
      user_name: {
        QueryFilter,
        :by_association_field,
        [:user],
        :name,
        :==,
        _filter_with_nil_values = false,
        _fallback_value = nil
      },
      backup_user_id: {
        QueryFilter,
        :by_association_field,
        [:backup_user],
        :id,
        :==,
        _filter_with_nil_values = false,
        _fallback_value = nil
      }
    ]

    built_query =
      QueryEngine.build(
        TestSchemaOne,
        filter_specs,
        %{"filters" => %{"user_name" => "Alice", "backup_user_id" => 1}},
        _opts = []
      )

    assert built_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, left_join: u1 in QueryEngineTest.User, as: :backup_user, on: t0.backup_user_id == u1.id, left_join: u2 in QueryEngineTest.User, as: :user, on: t0.user_id == u2.id, where: u1.id == ^1, where: u2.name == ^\"Alice\">}"
  end

  test "by association with a different operator" do
    filter_specs = [
      user_name: {
        QueryFilter,
        :by_association_field,
        [:user],
        :name,
        :!=,
        _filter_with_nil_values = false,
        _fallback_value = nil
      }
    ]

    built_query =
      QueryEngine.build(
        TestSchemaOne,
        filter_specs,
        %{"filters" => %{"user_name" => "Alice"}},
        _opts = []
      )

    assert built_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, left_join: u1 in QueryEngineTest.User, as: :user, on: t0.user_id == u1.id, where: u1.name != ^\"Alice\">}"
  end

  test "multiple associations with a deep association and different operator" do
    filter_specs = [
      user_name_not: {
        QueryFilter,
        :by_association_field,
        [:user],
        :name,
        :!=,
        _filter_with_nil_values = false,
        _fallback_value = nil
      },
      backup_user_creation_after: {
        QueryFilter,
        :by_association_field,
        [:backup_user],
        :inserted_at,
        :>=,
        _filter_with_nil_values = false,
        _fallback_value = nil
      }
    ]

    built_query =
      QueryEngine.build(
        TestSchemaOne,
        filter_specs,
        %{
          "filters" => %{
            "user_name_not" => "Alice",
            "backup_user_creation_after" => "1970-01-01T00:00:00Z"
          }
        },
        _opts = []
      )
    assert built_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, left_join: u1 in QueryEngineTest.User, as: :backup_user, on: t0.backup_user_id == u1.id, left_join: u2 in QueryEngineTest.User, as: :user, on: t0.user_id == u2.id, where: u1.inserted_at >= ^\"1970-01-01T00:00:00Z\", where: u2.name != ^\"Alice\">}"
  end

  test "filtering on associations that do not exist" do
    filter_specs = [
      user_name: {
        QueryFilter,
        :by_association_field,
        [:nonexistent],
        :name,
        :==,
        _filter_with_nil_values = false,
        _fallback_value = nil
      }
    ]

    assert_raise ArgumentError,
      "No valid binding found for expected alias: :nonexistent",
      fn ->
        QueryEngine.build(
          TestSchemaOne,
          filter_specs,
          %{"filters" => %{"user_name" => "Alice"}},
          _opts = []
        )
      end
  end

  test "filtering on fields that do not exist" do
    filter_specs = [
      nonexistent_field: {
        QueryFilter,
        :by_field,
        :nonexistent_field,
        :==,
        _filter_with_nil_values = false,
        _fallback_value = nil
      }
    ]

    assert_raise ArgumentError,
      "Field `nonexistent_field` does not exist on schema `QueryEngineTest.TestSchemaOne`",
      fn ->
        QueryEngine.build(
          TestSchemaOne,
          filter_specs,
          %{"filters" => %{"nonexistent_field" => "value"}},
          _opts = []
        )
      end
  end

  test "with sort specs" do
    sort_specs = [
      {
        :created_at,
        {
          QuerySort,
          :by_field,
          :created_at,
          :desc,
          _default = true
        }
      },
      {
        :user_id,
        {
          QuerySort,
          :by_field,
          :user_id,
          :asc,
          _default = false
        }
      }
    ]

    built_sorted_query =
      QueryEngine.build(
        TestSchemaOne,
        _filter_specs = [],
        %{"sort" => ["user_id:desc"]},
        sort_specs: sort_specs
      )

    built_default_sorted_query =
      QueryEngine.build(
        TestSchemaOne,
        _filter_specs = [],
        %{},
        sort_specs: sort_specs
      )

    assert built_sorted_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, order_by: [desc: t0.user_id]>}"

    assert built_default_sorted_query |> inspect() ==
             "{:ok, #Ecto.Query<from t0 in QueryEngineTest.TestSchemaOne, order_by: [desc: t0.created_at]>}"
  end
end
