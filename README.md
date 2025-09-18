# Outerfaces Ecto API Query System

[![Hex.pm](https://img.shields.io/hexpm/v/outerfaces_ex_ecto_api.svg)](https://hex.pm/packages/outerfaces_ex_ecto_api)
[![HexDocs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/outerfaces_ex_ecto_api)

A comprehensive, declarative query building and serialization system for Phoenix/Ecto applications that supports complex filtering, sorting, pagination, and deep association preloading through JSON API requests.

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
Provides a macro for schemas to define their serialization behavior with hooks for custom field processing.

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
