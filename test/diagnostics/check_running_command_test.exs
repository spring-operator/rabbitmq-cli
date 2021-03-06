## The contents of this file are subject to the Mozilla Public License
## Version 1.1 (the "License"); you may not use this file except in
## compliance with the License. You may obtain a copy of the License
## at http://www.mozilla.org/MPL/
##
## Software distributed under the License is distributed on an "AS IS"
## basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
## the License for the specific language governing rights and
## limitations under the License.
##
## The Original Code is RabbitMQ.
##
## The Initial Developer of the Original Code is GoPivotal, Inc.
## Copyright (c) 2007-2019 Pivotal Software, Inc.  All rights reserved.

defmodule CheckRunningCommandTest do
  use ExUnit.Case
  import TestHelper

  @command RabbitMQ.CLI.Diagnostics.Commands.CheckRunningCommand

  setup_all do
    RabbitMQ.CLI.Core.Distribution.start()

    start_rabbitmq_app()

    on_exit([], fn ->
      start_rabbitmq_app()
    end)

    :ok
  end

  setup context do
    {:ok, opts: %{
        node: get_rabbit_hostname(),
        timeout: context[:test_timeout] || 30000
      }}
  end

  test "merge_defaults: nothing to do" do
    assert @command.merge_defaults([], %{}) == {[], %{}}
  end

  test "validate: treats positional arguments as a failure" do
    assert @command.validate(["extra-arg"], %{}) == {:validation_failure, :too_many_args}
  end

  test "validate: treats empty positional arguments and default switches as a success" do
    assert @command.validate([], %{}) == :ok
  end

  @tag test_timeout: 3000
  test "run: targeting an unreachable node throws a badrpc", context do
    assert @command.run([], Map.merge(context[:opts], %{node: :jake@thedog})) == {:badrpc, :nodedown}
  end

  test "run: when the RabbitMQ app is booted and started, returns true", context do
    await_rabbitmq_startup()

    assert @command.run([], context[:opts])
  end

  test "run: when the RabbitMQ app is stopped, returns false", context do
    stop_rabbitmq_app()

    refute is_rabbitmq_app_running()
    refute @command.run([], context[:opts])

    start_rabbitmq_app()
  end

  test "output: when the result is true, returns successfully", context do
    assert match?({:ok, _}, @command.output(true, context[:opts]))
  end

  # this is a check command
  test "output: when the result is false, returns an error", context do
    assert match?({:error, _}, @command.output(false, context[:opts]))
  end
end
