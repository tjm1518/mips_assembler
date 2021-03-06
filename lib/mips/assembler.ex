defmodule Mips.Assembler do
  import Mips.Resolvers
  @moduledoc """
  Contains the main functions for assembling the MIPS assembly to machine code.
  """

  @spec assemble() :: :ok
  @spec assemble_one(binary) :: :ok
  @spec write_hex([{bitstring(), binary()},...]) :: :ok
  @spec assemble_file({binary, list(binary)}) :: {bitstring, binary}
  @spec expand_early(list({binary, integer})) :: {list(any), any}
  @spec read_files() :: list(list(binary()))
  @spec format_file(lines::list(binary())) :: list(binary())

  @doc """
    Run the assembler on each .s or .asm file, converting it to MIPS machine code.

    ### Input:
    Any file containing MIPS assembly in `resources/0-assembly/` ending with .asm or .s
    ### Output:
    An array containing lists of MIPS machine code in pure hexidecimal form & the corresponding file names.
  """

  def assemble do
    read_files()
    |> Enum.map(&Task.async(fn -> try do assemble_file(&1) catch _,reason -> {:err, reason} end end))
    |> Task.await_many(:infinity)
    |> Enum.map(fn
      {:err, exception} -> Exception.message(exception) |> IO.warn([])
      x -> x
    end)
    |> Enum.reject(&:ok==&1)
    |> write_hex()
  end


  @doc """
  Assemble a single file specified by the user rather than all files in resources/0-assembly/
  """

  def assemble_one(f_name) do
    {m_code, _} = {f_name, File.read!(f_name)
      |> String.replace(~r/#.*$/m, "")
      |> String.replace(~r/(?<_>[a-z|_]+):([[:space:]]*)/im,"\\g{1}:\s")
      |> String.split(~r/[[:space:]]*\n[[:space:]]*/)
      |> Enum.with_index(1)
      |> format_file()}
    |> assemble_file()
    String.replace(f_name, ~r/\.(asm|s)\z/, ".hex")
    |> File.write!(m_code, [:raw])
  end

  ###################################
  # Write the outputs to a hex file #

  defp write_hex(hexes) do
    File.cd!("1-hex", fn ->
      Enum.each(hexes, fn
        {m_code, f_name} ->
          String.replace(f_name, ~r/\.(asm|s)\z/, ".hex")
          |> File.write!(m_code, [:raw])
          _ -> nil
      end)
    end)
  end

  ###################################################
  # Assemble a single file containing mips assembly #

  defp assemble_file({f_name, lines}) do
    {_,text,data} = Enum.reduce(lines, {true,[],[]}, fn
      {<<".globl ", _::bits>>,_}, {x,text,data} -> {x,text,data}
      {<<".global ",_::bits>>,_}, {x,text,data} -> {x,text,data}
      {".data",_}, {_,text,data} -> {false,text,data}
      {".text",_}, {_,text,data} -> {true ,text,data}
      line, {true, text,data} -> {true ,[line|text],data}
      line, {false,text,data} -> {false,text,[line|data]}
    end)
    # Because of how Elixir/Erlang handles lists, it's faster to assemble the list back to front then reverse them.
    content = Enum.reverse(text) ++ Enum.reverse(data)

    {instructions, labels} = try do
      expand_early(content)
     catch
      :throw, {:label, label} ->
        lns = Enum.filter(lines, fn {txt, _} -> String.contains?(txt, label <> ":") end)
        |> Enum.map(&elem(&1, 1))
        Mips.Exception.raise(file: f_name, line: hd(lns), message: "Label '#{label} declared multiple times on lines: #{Enum.join(lns, ", ")}")
      :throw, {l_num, reason} -> Mips.Exception.raise(file: f_name, line: l_num, message: reason)
    end
    {Enum.map(instructions, fn
      {{:mem, op}, _} -> op
      {%{align: to}, _} -> %{align: to}
      {op, l_num} ->
        try do
          Regex.run(~r/(?<a>([^\s]+))(\s((?<ar0>([^,]+))(,\s(?<ar1>([^,]+))(,\s(?<ar2>([^,]+)))?)?)?)?/, op, capture: :all_names)
          |> List.update_at(0, &String.downcase/1)
          |> Enum.reject(&""==&1)
          |> resolve_instruction(labels)
        catch
           :throw, {:mem_loc, label} ->
              Mips.Exception.raise(file: f_name, line: l_num, message: "Invalid offset #{label}. Argument should be a valid label or register offset.")
           :throw, {:instr, instr} ->
              Mips.Exception.raise(file: f_name, line: l_num, message: "Invalid instruction #{instr}")
           :throw, {:offset, int} ->
              Mips.Exception.raise(file: f_name, line: l_num, message: "Invalid offset #{int}. Offsets should be a valid label or offset.")
           :throw, {:register, reg} ->
              Mips.Exception.raise(file: f_name, line: l_num, message: "Invalid register #{reg}")
           :throw, {:label, label} ->
              Mips.Exception.raise(file: f_name, line: l_num, message: "Label '#{label}' was not found.")
        end
      end
    )
    |> Enum.reduce(<<>>, fn
      %{align: to}, acc ->
        size = (to * ceil(byte_size(acc) / to)) * 8 - bit_size(acc)
        <<acc::bits, 0::size(size)>>
      v, acc ->
        <<acc::bits, v::bits>>
      end
    ), f_name}
  end


  ###############################################################################################################################
  # Resolve the positions of labels in the code as well as expanding data and pseudo-instruction to find their memory footprint #

  defp expand_early(lines) do
    earlies = Enum.map(lines, fn {line, l_num} ->
      if Regex.match?(~r/[a-z|_]+:\s.*/, line) do
        [header, op] = String.split(line, ": ")
        try do
          case resolve_early(op) do
            x when is_list(x) -> Enum.map(x, &{&1, l_num}) |> List.update_at(0, &{header,&1})
            x -> {header, {x, l_num}}
          end
        catch
          :throw, reason -> throw {l_num, reason}
        end
      else
        resolve_early(line)
        |> case do
          x when is_map(x) -> {x, l_num}
          {:mem, x} when is_bitstring(x) -> {{:mem, x}, l_num}
          x -> Enum.map(x, &{&1, l_num})
        end
      end
    end)
    |> List.flatten()
    {Enum.map(earlies, fn {_, {x, l_num}} -> {x, l_num}; x -> x end), Enum.reduce(earlies, {%{}, 0}, fn
      {header, {{:mem, x}, l_num}}, {map, acc} when is_bitstring(x) ->
        if Map.has_key?(map, header) do
          throw {:header, header, l_num}
        else
          {Map.put(map, header, acc), acc + byte_size(x)}
        end
      {header, {%{align: to}, l_num}}, {map, acc} ->
        if Map.has_key?(map, header) do
          throw {:header, header, l_num}
        else
          {Map.put(map, header, acc), to * ceil(acc / to)}
        end
      {header, {_, l_num}}, {map, acc} ->
        if Map.has_key?(map, header) do
          throw {:header, header, l_num}
        else
          {Map.put(map, header, acc), acc + 4}
        end
      {x,_}, {map, acc} when is_bitstring(x) -> {map, acc + byte_size(x)}
      _, {map, acc} -> {map, acc + 4}
      {%{align: to},_}, {map, acc} ->  {map, to * ceil(acc / to)}
      end
    ) |> elem(0)}
  end


  ##################################################################
  # Read all files ending with .asm or .s in resources/0-assembly/ #

  defp read_files do
    File.cd!("0-assembly", fn ->
      File.ls!
      |> Enum.filter(&Regex.match?(~r/.+\.(asm|s)\z/, &1))
      |> Enum.map(fn f_name ->
        {f_name, File.read!(f_name)
          |> String.replace(~r/#.*$/m, "")
          |> String.replace(~r/(?<_>[a-z|_]+):([[:space:]]*)/im,"\\g{1}:\s")
          |> String.split(~r/[[:space:]]*\n[[:space:]]*/)
          |> Enum.with_index(1)
          |> format_file()}
      end)
    end)
  end


  #####################################################################
  # Format the file nicely to make pattern matching operations easier #

  defp format_file(lines) do
    Enum.map(lines, fn {line, i} ->
      String.trim(line)
      |> String.replace(~r/[[:space:]]+/, " ")
      |> String.replace(~r/[[:blank:]]?,[[:blank:]]?/, ",\s")
      |> String.split("\n")
      |> Enum.zip([i,i])
    end)
    |> List.flatten()
    |> Enum.reject(&elem(&1, 0) == "")
  end

end
