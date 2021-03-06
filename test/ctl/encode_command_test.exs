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

defmodule EncodeCommandTest do
  use ExUnit.Case, async: false

  @command RabbitMQ.CLI.Ctl.Commands.EncodeCommand

  test "validate: not providing exactly 2 arguments for encoding is reported as invalid", _context do
    assert match?(
      {:validation_failure, {:bad_argument, _}},
      @command.validate([], %{})
    )
    assert match?(
      {:validation_failure, {:bad_argument, _}},
      @command.validate(["value"], %{})
    )
    assert match?(
      {:validation_failure, :too_many_args},
      @command.validate(["value", "secret", "incorrect"], %{})
    )
  end

  test "validate: hash and cipher must be supported", _context do
    opts = %{cipher: :rabbit_pbe.default_cipher,
             hash: :rabbit_pbe.default_hash,
             iterations: :rabbit_pbe.default_iterations}
    assert match?(
      {:validation_failure, {:bad_argument, _}},
      @command.validate(["value", "secret"], Map.merge(opts, %{cipher: :funny_cipher}))
    )
    assert match?(
      {:validation_failure, {:bad_argument, _}},
      @command.validate(["value", "secret"], Map.merge(opts, %{hash: :funny_hash}))
    )
    assert match?(
      {:validation_failure, {:bad_argument, _}},
      @command.validate(["value", "secret"], Map.merge(opts, %{cipher: :funny_cipher, hash: :funny_hash}))
    )
    assert match?(
      :ok,
      @command.validate(["value", "secret"], opts)
    )
  end

  test "validate: number of iterations must greather than 0", _context do
    opts = %{cipher: :rabbit_pbe.default_cipher,
             hash: :rabbit_pbe.default_hash,
             iterations: :rabbit_pbe.default_iterations}
    assert match?(
      {:validation_failure, {:bad_argument, _}},
      @command.validate(["value", "secret"], Map.merge(opts, %{iterations: 0}))
    )
    assert match?(
      {:validation_failure, {:bad_argument, _}},
      @command.validate(["value", "secret"], Map.merge(opts, %{iterations: -1}))
    )
    assert match?(
      :ok,
      @command.validate(["value", "secret"], opts)
    )
  end

  test "run: encrypt/decrypt", _context do
    # erlang list/string
    encrypt_decrypt(to_charlist("foobar"))
    # binary
    encrypt_decrypt("foobar")
    # tuple
    encrypt_decrypt({:password, "secret"})
  end

  defp encrypt_decrypt(secret) do
    secret_as_erlang_term = format_as_erlang_term(secret)
    passphrase = "passphrase"
    cipher = :rabbit_pbe.default_cipher()
    hash = :rabbit_pbe.default_hash()
    iterations = :rabbit_pbe.default_iterations()
    opts = %{cipher:       cipher,
             hash:         hash,
             iterations:   iterations
    }
    {:ok, output} = @command.run([secret_as_erlang_term, passphrase], opts)
    {:encrypted, encrypted} = output
    # decode plain value
    assert secret === :rabbit_pbe.decrypt_term(cipher, hash, iterations, passphrase, encrypted)
    # decode {encrypted, ...} tuple form
    assert secret === :rabbit_pbe.decrypt_term(cipher, hash, iterations, passphrase, encrypted)
  end

  defp format_as_erlang_term(value), do: to_string(:lists.flatten(:io_lib.format("~p", [value])))

end
