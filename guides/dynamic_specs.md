# Dynamic Query Specifications

One of the distinguishing features of this query engine is that filter and sort specifications are **first-class data structures** that can be constructed, composed, and manipulated at runtime.

## Why This Matters

Most query builders and ORMs fall into one of two camps:

1. **Direct query builders** (Ecto, ActiveRecord, Prisma) - Powerful but imperative. You write queries directly.
2. **Convention-based filters** (Ransack, django-filter) - Declarative but rigid. Conventions are baked in at compile time.

This library takes a different approach: you define **query capability specifications** as data, then the engine interprets them at runtime. This is closer to policy-as-data patterns (like OPA/Rego for authorization) than traditional ORMs.

## Specs Are Just Data

A filter spec is a tuple:

```elixir
{:filter_key, {Module, :function, field_or_path, operator, allow_nil, default}}
```

There's nothing special about this tuple - it's plain Elixir data. This means you can:

### Build Specs from Configuration

```elixir
defmodule MyApp.FilterConfig do
  def load_filter_specs(resource_type) do
    # Load from database, config file, or external service
    config = MyApp.Repo.get_by(FilterConfig, resource: resource_type)

    Enum.map(config.filters, fn filter ->
      {String.to_atom(filter["key"]),
       {QueryFilter,
        String.to_atom(filter["method"]),
        String.to_atom(filter["field"]),
        String.to_atom(filter["operator"]),
        filter["allow_nil"],
        filter["default"]}}
    end)
  end
end
```

### Generate Specs via Introspection

```elixir
defmodule MyApp.AutoSpecs do
  alias OuterfacesEctoApi.QueryEngine.QueryFilter

  @doc """
  Auto-generate filter specs for all fields on a schema.
  """
  def for_schema(schema) do
    schema.__schema__(:fields)
    |> Enum.reject(&(&1 in [:id, :inserted_at, :updated_at]))
    |> Enum.map(fn field ->
      {field, {QueryFilter, :by_field, field, :==, false, nil}}
    end)
  end

  @doc """
  Auto-generate association filter specs.
  """
  def for_associations(schema) do
    schema.__schema__(:associations)
    |> Enum.flat_map(fn assoc_name ->
      assoc = schema.__schema__(:association, assoc_name)
      related_schema = assoc.related

      # Create filters for each field on the related schema
      related_schema.__schema__(:fields)
      |> Enum.map(fn field ->
        key = String.to_atom("#{assoc_name}_#{field}")
        {key, {QueryFilter, :by_association_field, [assoc_name], field, :==, false, nil}}
      end)
    end)
  end
end
```

### Compose Specs from Multiple Sources

```elixir
defmodule MyApp.ResourceController do
  alias OuterfacesEctoApi.QueryEngine

  # Base specs that always apply
  @base_filters [
    {:is_active, {QueryFilter, :by_field, :archived_at, {:is_nil, :not_nil}, false, true}}
  ]

  def index(conn, params) do
    # Compose specs at runtime
    filter_specs =
      @base_filters ++
      tenant_scoped_filters(conn) ++
      user_permission_filters(conn) ++
      feature_flag_filters(conn)

    QueryEngine.all(Repo, Resource, [], filter_specs, [], params)
    |> then(fn {:ok, response} -> json(conn, response) end)
  end

  defp tenant_scoped_filters(conn) do
    tenant_id = conn.assigns.current_tenant.id
    [{:tenant_id, {QueryFilter, :by_field, :tenant_id, :==, false, tenant_id}}]
  end

  defp user_permission_filters(conn) do
    case conn.assigns.current_user.role do
      :admin -> []  # Admins see everything
      :manager -> [{:department_id, {QueryFilter, :by_field, :department_id, :==, false, conn.assigns.current_user.department_id}}]
      _ -> [{:owner_id, {QueryFilter, :by_field, :owner_id, :==, false, conn.assigns.current_user.id}}]
    end
  end

  defp feature_flag_filters(conn) do
    if MyApp.FeatureFlags.enabled?(:advanced_filters, conn.assigns.current_user) do
      MyApp.AdvancedFilters.specs_for(Resource)
    else
      []
    end
  end
end
```

## Multi-Tenant Query APIs

A powerful pattern is building per-tenant queryable field configurations:

```elixir
defmodule MyApp.TenantQueryConfig do
  @doc """
  Each tenant can configure which fields are queryable via their API.
  """
  def filter_specs_for_tenant(schema, tenant) do
    # Load tenant's allowed filters from database
    allowed = MyApp.Repo.all(
      from tc in TenantFilterConfig,
      where: tc.tenant_id == ^tenant.id and tc.schema == ^to_string(schema)
    )

    Enum.map(allowed, fn config ->
      {String.to_atom(config.filter_key),
       build_filter_tuple(config)}
    end)
  end

  defp build_filter_tuple(config) do
    case config.filter_type do
      "field" ->
        {QueryFilter, :by_field,
         String.to_atom(config.field),
         String.to_atom(config.operator),
         config.allow_nil,
         config.default_value}

      "association" ->
        path = config.association_path |> Enum.map(&String.to_atom/1)
        {QueryFilter, :by_association_field,
         path,
         String.to_atom(config.field),
         String.to_atom(config.operator),
         config.allow_nil,
         config.default_value}
    end
  end
end
```

## Plugin Architecture

Modules can contribute their own specs to a central registry:

```elixir
defmodule MyApp.QueryRegistry do
  use GenServer

  def register_filters(schema, specs) do
    GenServer.call(__MODULE__, {:register, schema, :filters, specs})
  end

  def get_filters(schema) do
    GenServer.call(__MODULE__, {:get, schema, :filters})
  end

  # In your plugins/extensions:
  defmodule MyApp.AuditPlugin do
    def init do
      # Register audit-related filters for all schemas
      for schema <- MyApp.audited_schemas() do
        MyApp.QueryRegistry.register_filters(schema, [
          {:created_by, {QueryFilter, :by_field, :created_by_id, :==, false, nil}},
          {:updated_after, {QueryFilter, :by_field, :updated_at, :>=, false, nil}}
        ])
      end
    end
  end
end
```

## Implementation Note

This dynamic capability exists because the core join-building functions (`QueryJoiner.ensure_joins/2` and `QueryJoiner.do_join/6`) are implemented as **runtime functions**, not macros.

Early versions used macros with `bind_quoted`, which required all spec values to be compile-time literals. The current implementation processes specs entirely at runtime, enabling the patterns described above.

## Trade-offs

**Advantages:**
- Maximum flexibility for multi-tenant and plugin architectures
- Specs can be stored, versioned, and audited
- Easy to build admin UIs for configuring queryable fields
- No compile-time constraints on spec construction

**Considerations:**
- Slightly more runtime overhead than compile-time query generation
- Specs built from external data should be validated
- Error messages reference runtime values, not source code locations

For most applications, the flexibility benefits far outweigh the minimal performance cost.
