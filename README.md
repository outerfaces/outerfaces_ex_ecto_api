# Outerfaces Ecto API Query System

[![Hex.pm](https://img.shields.io/hexpm/v/outerfaces_ex_ecto_api.svg)](https://hex.pm/packages/outerfaces_ex_ecto_api)
[![HexDocs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/outerfaces_ex_ecto_api)

A comprehensive, spec-driven query building and serialization system for Phoenix/Ecto applications that supports complex filtering, sorting, pagination, and deep association preloading through JSON API requests.

## Key Features

- **Specs as Data**: Filter and sort specifications are first-class data structures that can be stored, composed, and generated at runtime
- **Deep Association Support**: Filter and sort on nested associations up to 21 levels deep with automatic join management
- **Declarative API**: Define what queries are possible, not how to build them
- **Smart Defaults**: Automatic fallback filters for tenant scoping, soft deletes, and security defaults
- **JSON-Native**: Clean request/response format designed for frontend consumption

## Philosophy

Most APIs end up in one of two places: a handful of rigid REST endpoints that never quite fit, or a GraphQL schema that tries to be everything to everyone.

This library takes a different path. Filter and sort specs are just data—tuples you can define, store, compose, and pass around. Want a `/api/active-users-by-region` endpoint? Define the specs, wire it up, ship it. Need a different view for a different client? New specs, new endpoint, minimal ceremony.

Over time you build up a collection of query patterns that map to how your domain actually gets used. It's oddly satisfying to see them accumulate—each one a small, focused tool rather than another parameter on a god endpoint.

The bet is that many specific endpoints are better than one flexible endpoint. Specs make spinning up new ones cheap enough that you actually do it.

## Architecture Overview

The system consists of several interconnected modules that work together to provide a clean, declarative API for building complex database queries:

```
Frontend JSON Request
    ↓
QueryEngine (orchestrator)
    ↓
QueryBuilder (parses & builds query)
    ↓
QueryJoiner (manages associations)
    ↓
QueryFilter/QueryExpressor (applies filters)
    ↓
QueryAssociator (preloads & serializes)
    ↓
QuerySerializer (transforms to JSON)
    ↓
Clean JSON Response
```

## Core Modules

### QueryEngine
The main entry point that orchestrates the entire query pipeline. Provides two main functions:
- `all/7` - For index endpoints with pagination
- `get/5` - For show endpoints

### QueryBuilder
Parses JSON query parameters and builds Ecto queries using declarative filter and sort specifications. Handles a sophisticated two-phase filtering process:

1. **Explicit Filters**: Applies filters explicitly provided in the JSON request
2. **Default Filters**: Applies default/fallback filters for any missing filter specifications

### QueryJoiner
Manages association joins with automatic deduplication and nested alias tracking. Uses runtime functions (not macros) to allow fully dynamic join chain construction from runtime-computed specifications.

### QueryFilter
Applies filters to queries with support for:
- Simple field filtering
- Deep association filtering (up to 21 levels deep)
- Conditional operators based on values
- Default fallback filters with multiple fallback strategies

### QueryExpressor
Generates dynamic Ecto query expressions for different binding arities. Handles the complex task of building type-safe dynamic queries with proper variable binding.

### QueryAssociator
Manages preloading of associations and delegates serialization to individual schemas.

### QuerySerializer
Provides a `use` macro for schemas to define their serialization behavior with hooks for custom field processing.

## Usage

### 1. Define Filter Specifications

```elixir
# In your controller or filter module
@index_filters [
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
  },
  {
    :tenant_id,
    {
      QueryFilter,
      :by_field,
      :tenant_id,
      :==,
      _allow_nil = false,
      _default_or_fallback_filter = nil
    }
  },
  {
    :custom_field,
    {
      QueryFilter,
      :by_field,
      :field_name,
      :==,
      _allow_nil = false,
      _default_or_fallback_filter = nil
    }
  },
  {
    :association_filter,
    {
      QueryFilter,
      :by_association_field,
      [:user, :profile],  # Association path
      :name,
      :==,
      _allow_nil = false,
      _default_or_fallback_filter = nil
    }
  }
]
```

### 2. Define Sort Specifications

```elixir
@index_sorts [
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
    :by_some_id,
    {
      QuerySort,
      :by_field,
      :some_id,
      :asc,
      _default = false
    }
  },
  {
    :custom_sort,
    {
      QuerySort,
      :by_association_field,
      [:user],
      :name,
      :asc,
      _default = false
    }
  }
]
```

### 3. Define Preload Specifications

```elixir
@index_preloads [
  :simple_association,
  {:nested_association, [:deep_nested]},
  {
    :complex_association,
    [
      nested_field: [:deep_field],
      another_nested: [
        :sound_generation_profile,
        :audio_control_mode
      ]
    ]
  }
]
```

### 4. Use in Controllers

```elixir
def index(conn, params) do
  QueryEngine.all(
    Repo,
    MySchema,
    @index_preloads,
    @index_filters,
    @index_sorts,
    params
  )
  |> then(fn {:ok, response} -> json(conn, response) end)
end

def show(conn, %{"id" => id}) do
  QueryEngine.get(Repo, MySchema, id, @show_preloads)
  |> then(fn {_status, response} -> json(conn, response) end)
end
```

### 5. Add Serialization to Schemas

```elixir
defmodule MyApp.MySchema do
  use Ecto.Schema
  use OuterfacesEctoApi.QueryEngine.QuerySerializer

  # Override serialization behavior
  def serializer_skip_fields(_opts), do: [:internal_field, :password_hash]

  def do_serialize_field(:created_at, value, _opts) do
    # Custom date formatting
    DateTime.to_iso8601(value)
  end
  
  def do_serialize_field(_field, value, _opts), do: value
end
```

## Frontend Usage

### JSON Query Format

```javascript
const queryParams = {
  query: JSON.stringify({
    filters: {
      is_active: true,
      tenant_id: 123,
      association_filter: "John"
    },
    sort: ["created_at:desc", "custom_sort:desc"]
  }),
  limit: 50,
  offset: 0
}

fetch(`/api/resources?${new URLSearchParams(queryParams)}`)
```

### Response Format

```javascript
{
  status: 200,
  results: {
    data: [
      {
        id: 1,
        name: "Resource 1",
        schema: "MyApp.MySchema"
      }
    ],
    page_info: {
      limit: 50,
      offset: 0,
      total_count: 200,
      total_pages: 4,
      has_next_page: true,
      has_previous_page: false
    },
    schema: "MyApp.MySchema"
  }
}
```

## Filter Specification Format

```elixir
{
  :filter_key,  # Key that appears in JSON filters
  {
    Module,           # Module containing filter function
    :function_name,   # Function to call
    :field_or_binding_list,  # Field name or association path
    :operator,        # :==, :!=, :>, :<, etc. or {:truthy_op, :falsy_op}
    allow_nil,        # boolean - whether to apply filter with nil values
    default_value     # Default value or {Module, :func, args} for default filter
  }
}
```

## Sort Specification Format

```elixir
{
  :sort_key,  # Key that appears in JSON sort array
  {
    Module,           # Module containing sort function  
    :function_name,   # Function to call
    binding_list,     # Association path ([] for direct field)
    :field_name,      # Field to sort on
    :direction,       # :asc or :desc
    is_default        # boolean - whether this is a default sort
  }
}
```

## Advanced Features

### Default Filter Mechanism

The system automatically applies fallback filters when they're not explicitly provided in requests. This enables tenant scoping, soft deletes, security defaults, and better user experience.

#### Conditional Operators (Most Common)

The most powerful feature allows operators to change based on the filter value's truthiness:

```elixir
def is_active() do
  {
    :is_active,
    {
      QueryFilter,
      :by_field,
      :archived_at,
      {:is_nil, :not_nil},    # Conditional operators
      false,                   # Don't filter on explicit nil values  
      true                     # Default to active (true)
    }
  }
end
```

**Behavior:**
- `is_active: true` → `WHERE archived_at IS NULL` (active records)
- `is_active: false` → `WHERE archived_at IS NOT NULL` (archived records)
- `is_active: null` → Filter skipped (allow_nil = false)
- Request without `is_active` → `WHERE archived_at IS NULL` (defaults to active)

#### Default Filter Processing

1. **Explicit Filters First**: Processes filters provided in the JSON request
2. **Default Filters Second**: Applies defaults for missing filters only

**Override Prevention**: Defaults only apply when the filter key is completely missing:
```elixir
# {"filters": {"is_active": null}} → Filter skipped (explicit null)
# {"filters": {}} → Default applied (key missing)
```

#### Default Value Types

**Literal Values** (most common):
```elixir
{:tenant_scoped, {QueryFilter, :by_field, :tenant_id, :==, false, 123}}
# When not provided, filters by tenant_id = 123
```

**Function Calls**:
```elixir
{:tenant_id, {QueryFilter, :by_field, :tenant_id, :==, false, {MyModule, :current_tenant_id, []}}}
# Calls MyModule.current_tenant_id() to get default value
```

**Nil with `allow_nil` flag**:
```elixir
{:optional, {QueryFilter, :by_field, :field, :==, true, nil}}
# If allow_nil = true: applies filter with nil value
# If allow_nil = false: skips filter entirely
```

### Conditional Operators
```elixir
# Operator changes based on filter value
{:is_active, {QueryFilter, :by_field, :archived_at, {:is_nil, :not_nil}, false, true}}
# When is_active: true -> uses :is_nil
# When is_active: false -> uses :not_nil
# When not provided -> defaults to true, uses :is_nil
```

### Default Filters
```elixir
# Applied when filter not explicitly provided
{:tenant_scoped, {QueryFilter, :by_field, :tenant_id, :==, false, current_tenant_id}}
```

### Deep Association Filtering
```elixir
# Filter by nested association fields
{:user_profile_type, {QueryFilter, :by_association_field, [:user, :profile], :type, :==, false, nil}}
```

### Dynamic Spec Construction

Unlike most query builders that require compile-time definitions, specs here are plain data that can be constructed at runtime:

```elixir
# Build specs dynamically from configuration or database
def build_filter_specs(schema, config) do
  Enum.map(config.filterable_fields, fn field_config ->
    {field_config.key,
     {QueryFilter, :by_field, field_config.column, field_config.operator, false, nil}}
  end)
end

# Generate specs via schema introspection
def auto_filter_specs(schema) do
  schema.__schema__(:fields)
  |> Enum.map(fn field ->
    {field, {QueryFilter, :by_field, field, :==, false, nil}}
  end)
end

# Compose specs from multiple sources
def merged_specs(base_specs, tenant_specs, user_specs) do
  base_specs ++ tenant_specs ++ user_specs
end
```

This enables:
- Loading filter/sort capabilities from a database
- Auto-generating query APIs from schema introspection
- Multi-tenant configurations with per-tenant queryable fields
- Plugin systems where modules contribute their own specs

## JavaScript Codegen

The library includes a Mix task to generate JSDoc type definitions from your Ecto schemas, keeping frontend types in sync with your API.

### Basic Usage

```bash
mix outerfaces_ex_ecto_api.js_codegen schema=MyApp.User target_project_name=my_frontend
```

Generates type definitions based on schema fields and associations:

```javascript
/**
 * @typedef {Object} User
 * @property {number} id
 * @property {string} name
 * @property {string} email
 * @property {string} inserted_at
 * @property {string} updated_at
 * @property {Organization | null} organization
 */
```

### Controller-Aware Generation

When you specify a controller, it generates endpoint-specific types based on what's actually preloaded for index vs show:

```bash
mix outerfaces_ex_ecto_api.js_codegen \
  schema=MyApp.User \
  controller_module=MyAppWeb.UserController \
  target_project_name=my_frontend
```

This reads `index_preloads/0` and `show_preloads/0` from your controller to generate accurate types for each endpoint. (The `/0` convention is simple but could be extended to `/1` variants that accept context for conditional preloads, role-based field visibility, etc.)

```javascript
/**
 * @typedef {Object} UserIndexData
 * @property {number} id
 * @property {string} name
 * @property {Organization | null} organization
 */

/**
 * @typedef {Object} FetchUserIndexQueryParams
 * @property {Object} [filters] - Filters to apply to the query
 * @property {string[]} [sort] - Sort order. Format: ['field:asc', 'field:desc']
 * @property {number} [limit] - Maximum records to return
 * @property {number} [offset] - Offset for pagination
 */

/**
 * @typedef {Object} FetchUserIndexQueryResult
 * @property {number} status
 * @property {Object} results
 * @property {UserIndexData[]} results.data
 * @property {string} results.schema
 * @property {PageInfo} results.page_info
 */

/**
 * @typedef {Object} UserShowData
 * @property {number} id
 * @property {string} name
 * @property {string} email
 * @property {Organization | null} organization
 * @property {Profile | null} profile
 */

/**
 * @typedef {Object} FetchUserShowQueryResult
 * @property {number} status
 * @property {Object} result
 * @property {UserShowData} result.data
 * @property {string} result.schema
 */
```

### Skipping Fields

If your schema uses `QuerySerializer`, fields listed in `serializer_skip_fields/1` are automatically excluded from the generated types:

```elixir
defmodule MyApp.User do
  use OuterfacesEctoApi.QueryEngine.QuerySerializer

  def serializer_skip_fields(_opts), do: [:password_hash, :internal_notes]
end
```

This keeps sensitive or internal fields out of your frontend type definitions.
