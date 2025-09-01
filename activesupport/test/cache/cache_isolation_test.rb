# frozen_string_literal: true

require_relative "../abstract_unit"
require "active_support/cache"

class CacheIsolationTest < ActiveSupport::TestCase
  def setup
    @store = ActiveSupport::Cache::MemoryStore.new(namespace: "production")
  end

  test "namespace isolation with r: marker preserves original namespace" do
    original_namespace = @store.namespace
    assert_equal "production", original_namespace

    isolated_namespace = "#{SecureRandom.hex(6)}r:#{original_namespace}"
    @store.namespace = isolated_namespace

    assert_match(/^[a-f0-9]{12}r:production$/, @store.namespace)
    assert @store.namespace.end_with?("r:production")
  end

  test "namespace isolation replaces existing r: marker" do
    @store.namespace = "abc123r:production"

    new_random = SecureRandom.hex(6)
    isolated_namespace = "#{new_random}r:" + @store.namespace.split("r:", 2)[-1]
    @store.namespace = isolated_namespace

    assert_match(/^[a-f0-9]{12}r:production$/, @store.namespace)
    assert_not_equal "abc123r:production", @store.namespace
    assert @store.namespace.end_with?("r:production")
  end

  test "namespace isolation handles complex namespaces" do
    @store.namespace = "foo:bar:baz"

    isolated_namespace = "#{SecureRandom.hex(6)}r:#{@store.namespace}"
    @store.namespace = isolated_namespace

    assert_match(/^[a-f0-9]{12}r:foo:bar:baz$/, @store.namespace)
  end

  test "namespace isolation handles nil namespace" do
    @store = ActiveSupport::Cache::MemoryStore.new
    assert_nil @store.namespace

    isolated_namespace = "#{SecureRandom.hex(6)}r"
    @store.namespace = isolated_namespace

    assert_match(/^[a-f0-9]{12}r$/, @store.namespace)
  end

  test "cache operations work with isolated namespace" do
    @store.namespace = "#{SecureRandom.hex(6)}r:test"

    @store.write("key", "value")
    assert_equal "value", @store.read("key")

    @store.namespace = "#{SecureRandom.hex(6)}r:test"
    assert_nil @store.read("key")
  end
end
