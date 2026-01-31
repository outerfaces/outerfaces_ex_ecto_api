defmodule QueryJoinerTest do
  @moduledoc """
  Tests for QueryJoiner that specifically exercise the runtime function behavior.

  These tests verify that ensure_joins and do_join work correctly when called with
  runtime values (variables computed at runtime) rather than compile-time literals.

  This is critical because the functions were previously macros, and calling macros
  with runtime values could cause macro expansion timing issues with bind_quoted.
  """
  use ExUnit.Case

  import Ecto.Query
  alias OuterfacesEctoApi.QueryEngine.QueryJoiner

  # Test schemas for join operations
  defmodule Organization do
    use Ecto.Schema

    schema "organizations" do
      field(:name, :string)
    end
  end

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)
      belongs_to(:organization, QueryJoinerTest.Organization)
    end
  end

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field(:title, :string)
      belongs_to(:user, QueryJoinerTest.User)
    end
  end

  defmodule Comment do
    use Ecto.Schema

    schema "comments" do
      field(:body, :string)
      belongs_to(:post, QueryJoinerTest.Post)
      belongs_to(:user, QueryJoinerTest.User)
    end
  end

  describe "do_join/6 with runtime values" do
    test "creates a basic left join with runtime variables" do
      # Simulate runtime values - these are NOT compile-time literals
      assoc_name = :user
      related_schema = User
      owner_key = :id
      related_key = :user_id

      query = from(p in Post)
      result = QueryJoiner.do_join(query, assoc_name, related_schema, owner_key, related_key)

      # Verify the join was added
      assert length(result.joins) == 1
      [join] = result.joins
      assert join.as == :user
      assert join.qual == :left
    end

    test "creates a nested join with parent alias using runtime variables" do
      # First join: Post -> User
      assoc_name_1 = :user
      related_schema_1 = User
      owner_key_1 = :id
      related_key_1 = :user_id

      # Second join: User -> Organization (nested under :user)
      assoc_name_2 = :organization
      related_schema_2 = Organization
      owner_key_2 = :id
      related_key_2 = :organization_id
      parent_alias = :user

      query = from(p in Post)

      query =
        QueryJoiner.do_join(query, assoc_name_1, related_schema_1, owner_key_1, related_key_1)

      query =
        QueryJoiner.do_join(
          query,
          assoc_name_2,
          related_schema_2,
          owner_key_2,
          related_key_2,
          parent_alias
        )

      # Verify both joins were added with correct aliases
      assert length(query.joins) == 2
      aliases = Enum.map(query.joins, & &1.as)
      assert :user in aliases
      assert :user_organization in aliases
    end

    test "handles join chain computed from a list at runtime" do
      # This simulates what QueryBuilder does - computing join info from params at runtime
      join_specs = [
        {:user, User, :id, :user_id},
        {:organization, Organization, :id, :organization_id}
      ]

      query = from(p in Post)

      # Build joins dynamically from runtime list
      {final_query, _} =
        Enum.reduce(join_specs, {query, nil}, fn
          {assoc_name, related_schema, owner_key, related_key}, {acc_query, parent_alias} ->
            new_query =
              QueryJoiner.do_join(
                acc_query,
                assoc_name,
                related_schema,
                owner_key,
                related_key,
                parent_alias
              )

            new_alias =
              if parent_alias,
                do: String.to_atom("#{parent_alias}_#{assoc_name}"),
                else: assoc_name

            {new_query, new_alias}
        end)

      assert length(final_query.joins) == 2
    end
  end

  describe "ensure_joins/2 with runtime values" do
    test "creates joins from a runtime chain variable" do
      # Chain computed at runtime (simulating extract_needed_joins output)
      chain = [
        {:user, User, :id, :user_id}
      ]

      query = from(p in Post)
      result = QueryJoiner.ensure_joins(query, chain)

      assert length(result.joins) == 1
      [join] = result.joins
      assert join.as == :user
    end

    test "creates nested joins from a runtime chain" do
      # Multi-step chain computed at runtime
      chain = [
        {:user, User, :id, :user_id},
        {:organization, Organization, :id, :organization_id}
      ]

      query = from(p in Post)
      result = QueryJoiner.ensure_joins(query, chain)

      assert length(result.joins) == 2
      aliases = Enum.map(result.joins, & &1.as)
      assert :user in aliases
      assert :user_organization in aliases
    end

    test "skips already existing joins" do
      chain = [{:user, User, :id, :user_id}]

      # Create query with existing join
      query =
        from(p in Post,
          left_join: u in User,
          as: :user,
          on: p.user_id == u.id
        )

      result = QueryJoiner.ensure_joins(query, chain)

      # Should still have only 1 join (not duplicated)
      assert length(result.joins) == 1
    end

    test "handles empty chain" do
      chain = []
      query = from(p in Post)
      result = QueryJoiner.ensure_joins(query, chain)

      assert result.joins == []
    end

    test "works with chain built dynamically from function" do
      # Simulate building chain from params at runtime
      build_chain = fn assoc_names ->
        Enum.map(assoc_names, fn
          :user -> {:user, User, :id, :user_id}
          :organization -> {:organization, Organization, :id, :organization_id}
        end)
      end

      # Chain is fully runtime - built from function call
      chain = build_chain.([:user])

      query = from(p in Post)
      result = QueryJoiner.ensure_joins(query, chain)

      assert length(result.joins) == 1
      [join] = result.joins
      assert join.as == :user
    end

    test "handles multiple independent chains in reduce (simulating QueryBuilder)" do
      # This mirrors QueryBuilder.build_index_query behavior
      chains = [
        [{:user, User, :id, :user_id}],
        [{:post, Post, :id, :post_id}]
      ]

      query = from(c in Comment)

      # Apply multiple chains via reduce - exactly how QueryBuilder does it
      result =
        Enum.reduce(chains, query, fn chain, acc_query ->
          QueryJoiner.ensure_joins(acc_query, chain)
        end)

      assert length(result.joins) == 2
      aliases = Enum.map(result.joins, & &1.as)
      assert :user in aliases
      assert :post in aliases
    end
  end

  describe "NamedBinding helpers" do
    alias OuterfacesEctoApi.QueryEngine.QueryJoiner.NamedBinding

    test "find/2 locates a named binding" do
      query =
        from(p in Post,
          left_join: u in User,
          as: :user,
          on: p.user_id == u.id
        )

      result = NamedBinding.find(query, :user)
      assert {1, join} = result
      assert join.as == :user
    end

    test "find/2 returns nil for missing binding" do
      query = from(p in Post)
      assert NamedBinding.find(query, :user) == nil
    end

    test "find_all/2 locates multiple bindings in order" do
      chain = [
        {:user, User, :id, :user_id},
        {:organization, Organization, :id, :organization_id}
      ]

      query = from(p in Post)
      query = QueryJoiner.ensure_joins(query, chain)

      result = NamedBinding.find_all(query, [:user, :organization])

      assert length(result) == 2
      [{alias1, _, _}, {alias2, _, _}] = result
      assert alias1 == :user
      assert alias2 == :user_organization
    end
  end
end
