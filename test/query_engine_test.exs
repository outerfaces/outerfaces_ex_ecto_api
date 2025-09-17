defmodule QueryEngineTest do
  use ExUnit.Case

  alias Hex.API.User
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
