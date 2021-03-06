defmodule Mips.Resolvers do
  import Mips.Pattern
  @moduledoc """
  Contains functions that resolve instructions and data directives to machine code.
  """

  @spec resolve_data(data::bitstring()) :: %{atom()  => integer()} | {:mem, bitstring()}
  @spec resolve_pseudo([binary]) :: list(binary)
  @spec resolve_early(inst::binary) :: %{atom()  => integer()} | list(binary) | {:mem, bitstring()}
  @spec resolve_instruction(op::[binary, ...], labels :: %{binary => integer}) :: <<_::32>>
  @spec pow_2(non_neg_integer) :: pos_integer

  @doc """
  Resolve a mips instruction to its hex equivilent.
  ### Inputs:
    A list with the op at the head and args as the tail
  ### Outputs:
    A 32 bit hex representation of the instruction.
  """

  def resolve_instruction(["sll",r0,r1,im],_) do
    d = register(r1)
    t = register(r0)
    i = integer(im)
    <<d::16,t::5,i::5,0::6>>
  end
  def resolve_instruction(["srl",r0,r1,im],_) do
    d = register(r1)
    t = register(r0)
    i = integer(im)
    <<d::16,t::5,i::5,2::6>>
  end
  def resolve_instruction(["sra",r0,r1,im],_) do
    d = register(r1)
    t = register(r0)
    i = integer(im)
    <<d::16,t::5,i::5,3::6>>
  end
  def resolve_instruction(["sllv",r0,r1,r2],_) do
    s = register(r2)
    t = register(r1)
    d = register(r0)
    <<s::11,t::5,d::5,4::11>>
  end
  def resolve_instruction(["jr",r0],_) do
    s = register(r0)
    <<s::11,8::21>>
  end
  def resolve_instruction(["jalr",r0],_) do
    s = register(r0)
    <<s::11,9::21>>
  end
  def resolve_instruction(["syscall"],_) do
    <<10::32>>
  end
  def resolve_instruction(["break"],_) do
    <<11::32>>
  end
  def resolve_instruction(["mfhi",r0],_) do
    d = register(r0)
    <<d::21,16::11>>
  end
  def resolve_instruction(["mthi",r0],_) do
    s = register(r0)
    <<s::11,17::21>>
  end
  def resolve_instruction(["mflo",r0],_) do
    d = register(r0)
    <<d::21,18::11>>
  end
  def resolve_instruction(["mtlo",r0],_) do
    s = register(r0)
    <<s::11,19::21>>
  end
  def resolve_instruction(["mult",r0,r1],_) do
    s = register(r0)
    t = register(r1)
    <<s::11,t::5,24::16>>
  end
  def resolve_instruction(["multu",r0,r1],_) do
    s = register(r0)
    t = register(r1)
    <<s::11,t::5,25::16>>
  end
  def resolve_instruction(["div",r0,r1],_) do
    s = register(r0)
    t = register(r1)
    <<s::11,t::5,26::16>>
  end
  def resolve_instruction(["divu",r0,r1],_) do
    s = register(r0)
    t = register(r1)
    <<s::11,t::5,27::16>>
  end
  def resolve_instruction(["add",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,32::11>>
  end
  def resolve_instruction(["addu",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,33::11>>
  end
  def resolve_instruction(["sub",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,34::11>>
  end
  def resolve_instruction(["subu",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,35::11>>
  end
  def resolve_instruction(["and",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,36::11>>
  end
  def resolve_instruction(["or",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,37::11>>
  end
  def resolve_instruction(["xor",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,38::11>>
  end
  def resolve_instruction(["nor",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,39::11>>
  end
  def resolve_instruction(["slt",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,42::11>>
  end
  def resolve_instruction(["sltu",r0,r1,r2],_) do
    d = register(r0)
    s = register(r1)
    t = register(r2)
    <<s::11,t::5,d::5,43::11>>
  end
  def resolve_instruction(["bgez",r0,a0],ls) do
    s = register(r0)
    try do
      i = integer(a0)
      <<1::6,s::5,1::5,i::16>>
    catch
      _,_ ->
        if Map.has_key?(ls, a0) do
          i = Map.get(ls, a0)
          <<1::6,s::5,1::5,i::16>>
        else
          throw {:offset, a0}
        end
    end
  end
  def resolve_instruction(["bgezal",r0,a0],ls) do
    s = register(r0)
    try do
      i = integer(a0)
      <<1::6,s::5,17::5,i::16>>
    catch
      _,_ ->
        if Map.has_key?(ls, a0) do
          i = Map.get(ls, a0)
          <<1::6,s::5,17::5,i::16>>
        else
          throw {:offset, a0}
        end
    end
  end
  def resolve_instruction(["bltz",r0,a0],ls) do
    s = register(r0)
    try do
      i = integer(a0)
      <<1::6,s::5,i::21>>
    catch
      _,_ ->
        if Map.has_key?(ls, a0) do
          i = Map.get(ls, a0)
          <<1::6,s::5,i::21>>
        else
          throw {:offset, a0}
        end
    end
  end
  def resolve_instruction(["bltzal",r0,a0],ls) do
    s = register(r0)
    try do
      i = integer(a0)
      <<1::6,s::5,16::5,i::16>>
    catch
      _,_ ->
        if Map.has_key?(ls, a0) do
          i = Map.get(ls, a0)
          <<1::6,s::5,16::5,i::16>>
        else
          throw {:offset, a0}
        end
    end
  end
  def resolve_instruction(["j",lb],ls) do
    if Map.has_key?(ls, lb) do
      l = Map.get(ls, lb)
      <<2::6,l::26>>
    else
      throw {:label, lb}
    end
  end
  def resolve_instruction(["jal",lb],ls) do
    if Map.has_key?(ls, lb) do
      l = Map.get(ls, lb)
      <<3::6,l::26>>
    else
      throw {:label, lb}
    end
  end
  def resolve_instruction(["beq",r0,r1,a0],ls) do
    s = register(r0)
    t = register(r1)
    try do
      i = integer(a0)
      <<4::6,s::5,t::5,i::16>>
    catch
      _,_ ->
        if Map.has_key?(ls, a0) do
          i = Map.get(ls, a0)
          <<4::6,s::5,t::5,i::16>>
        else
          throw {:offset, a0}
        end
    end
  end
  def resolve_instruction(["bne",r0,r1,a0],ls) do
    s = register(r0)
    t = register(r1)
    try do
      i = integer(a0)
      <<5::6,s::5,t::5,i::16>>
    catch
      _,_ ->
        if Map.has_key?(ls, a0) do
          i = Map.get(ls, a0)
          <<5::6,s::5,t::5,i::16>>
        else
          throw {:offset, a0}
        end
    end
  end
  def resolve_instruction(["blez",r0,a0],ls) do
    s = register(r0)
    try do
      i = integer(a0)
      <<6::6,s::5,i::21>>
    catch
      _,_ ->
        if Map.has_key?(ls, a0) do
          i = Map.get(ls, a0)
          <<6::6,s::5,i::21>>
        else
          throw {:offset, a0}
        end
    end
  end
  def resolve_instruction(["bgtz",r0,a0],ls) do
    s = register(r0)
    try do
      i = integer(a0)
      <<7::6,s::5,i::21>>
    catch
      _,_ ->
        if Map.has_key?(ls, a0) do
          i = Map.get(ls, a0)
          <<7::6,s::5,i::21>>
        else
          throw {:offset, a0}
        end
    end
  end
  def resolve_instruction(["addi",r0,r1,im],_) do
    t = register(r0)
    s = register(r1)
    i = integer(im)
    <<8::6,s::5,t::5,i::16>>
  end
  def resolve_instruction(["addiu",r0,r1,im],_) do
    t = register(r0)
    s = register(r1)
    i = integer(im)
    <<9::6,s::5,t::5,i::16>>
  end
  def resolve_instruction(["slti",r0,r1,im],_) do
    t = register(r0)
    s = register(r1)
    i = integer(im)
    <<10::6,s::5,t::5,i::16>>
  end
  def resolve_instruction(["sltiu",r0,r1,im],_) do
    t = register(r0)
    s = register(r1)
    i = integer(im)
    <<11::6,s::5,t::5,i::16>>
  end
  def resolve_instruction(["andi",r0,r1,im],_) do
    t = register(r0)
    s = register(r1)
    i = integer(im)
    <<12::6,s::5,t::5,i::16>>
  end
  def resolve_instruction(["ori",r0,r1,im],_) do
    t = register(r0)
    s = register(r1)
    i = integer(im)
    <<13::6,s::5,t::5,i::16>>
  end
  def resolve_instruction(["xori",r0,r1,im],_) do
    t = register(r0)
    s = register(r1)
    i = integer(im)
    <<14::6,s::5,t::5,i::16>>
  end
  def resolve_instruction(["lui",r0,im],_) do
    t = register(r0)
    i = integer(im)
    <<15::6,t::10,i::16>>
  end
  def resolve_instruction(["mfc0",r0,r1],_) do
    t = register(r0)
    d = register(r1)
    <<16::6,t::10,d::5,0::11>>
  end
  def resolve_instruction(["mtc0",r0,r1],_) do
    t = register(r0)
    d = register(r1)
    <<16::6,4::5,t::5,d::5,0::11>>
  end
  # Including pseudoinstruction "lb $r, <label>" which is resolved as "lb $r, label($0)"
  def resolve_instruction(["lb",r0,a1],ls) do
    t = register(r0)
    case Regex.run(~r/\A(?<off>(\d+))(\((?<reg>(\$.*)))\)\z/,a1,capture: :all_names) do
      [of, r1] ->
        o = integer(of)
        s = register(r1)
        <<32::6,s::5,t::5,o::16>>
      _ ->
        if Map.has_key?(ls, a1) do
          o = Map.get(ls, a1)
          <<32::6,t::10,o::16>>
        else
          throw {:mem_loc, a1}
        end
    end
  end
  # Including pseudoinstruction "lh $r, <label>" which is resolved as "lh $r, label($0)"
  def resolve_instruction(["lh",r0,a1],ls) do
    t = register(r0)
    case Regex.run(~r/\A(?<off>((0x)?((\d|[[:xdigit]])+)))(\((?<reg>(\$.*))\))\z/,a1,capture: :all_names) do
      [of, r1] ->
        o = integer(of)
        s = register(r1)
        <<33::6,s::5,t::5,o::16>>
      _ ->
        if Map.has_key?(ls, a1) do
          o = Map.get(ls, a1)
          <<33::6,t::10,o::16>>
        else
          throw {:mem_loc, a1}
        end
    end
  end
  # Including pseudoinstruction "lw $r, <label>" which is resolved as "lw $r, label($0)"
  def resolve_instruction(["lw",r0,a1],ls) do
    t = register(r0)
    case Regex.run(~r/\A(?<off>((0x)?((\d|[[:xdigit]])+)))(\((?<reg>(\$.*))\))\z/,a1,capture: :all_names) do
      [of, r1] ->
        o = integer(of)
        s = register(r1)
        <<35::6,s::5,t::5,o::16>>
      _ ->
        if Map.has_key?(ls, a1) do
          o = Map.get(ls, a1)
          <<35::6,t::10,o::16>>
        else
          throw {:mem_loc, a1}
        end
    end
  end
  # Including pseudoinstruction "lbu $r, <label>" which is resolved as "lbu $r, label($0)"
  def resolve_instruction(["lbu",r0,a1],ls) do
    t = register(r0)
    case Regex.run(~r/\A(?<off>((0x)?((\d|[[:xdigit]])+)))(\((?<reg>(\$.*))\))\z/,a1,capture: :all_names) do
      [of, r1] ->
        o = integer(of)
        s = register(r1)
        <<36::6,s::5,t::5,o::16>>
      _ ->
        if Map.has_key?(ls, a1) do
          o = Map.get(ls, a1)
          <<36::6,t::10,o::16>>
        else
          throw {:mem_loc, a1}
        end
    end
  end
  # Including pseudoinstruction "lhu $r, <label>" which is resolved as "lhu $r, label($0)"
  def resolve_instruction(["lhu",r0,a1],ls) do
    t = register(r0)
    case Regex.run(~r/\A(?<off>((0x)?((\d|[[:xdigit]])+)))(\((?<reg>(\$.*))\))\z/,a1,capture: :all_names) do
      [of, r1] ->
        o = integer(of)
        s = register(r1)
        <<37::6,s::5,t::5,o::16>>
      _ ->
        if Map.has_key?(ls, a1) do
          o = Map.get(ls, a1)
          <<37::6,t::10,o::16>>
        else
          throw {:mem_loc, a1}
        end
    end
  end
  # Including pseudoinstruction "sb $r, <label>" which is resolved as "sb $r, label($0)"
  def resolve_instruction(["sb",r0,a1],ls) do
    t = register(r0)
    case Regex.run(~r/\A(?<off>((0x)?((\d|[[:xdigit]])+)))(\((?<reg>(\$.*))\))\z/,a1,capture: :all_names) do
      [of, r1] ->
        o = integer(of)
        s = register(r1)
        <<40::6,s::5,t::5,o::16>>
      _ ->
        if Map.has_key?(ls, a1) do
          o = Map.get(ls, a1)
          <<40::6,t::10,o::16>>
        else
          throw {:mem_loc, a1}
        end
    end
  end
  # Including pseudoinstruction "sh $r, <label>" which is resolved as "sh $r, label($0)"
  def resolve_instruction(["sh",r0,a1],ls) do
    t = register(r0)
    case Regex.run(~r/\A(?<off>((0x)?((\d|[[:xdigit]])+)))(\((?<reg>(\$.*))\))\z/,a1,capture: :all_names) do
      [of, r1] ->
        o = integer(of)
        s = register(r1)
        <<41::6,s::5,t::5,o::16>>
      _ ->
        if Map.has_key?(ls, a1) do
          o = Map.get(ls, a1)
          <<41::6,t::10,o::16>>
        else
          throw {:mem_loc, a1}
        end
    end
  end
  # Including pseudoinstruction "sw $r, <label>" which is resolved as "sw $r, label($0)"
  def resolve_instruction(["sw",r0,a1],ls) do
    t = register(r0)
    case Regex.run(~r/\A(?<off>((0x)?((\d|[[:xdigit]])+)))(\((?<reg>(\$.*))\))\z/,a1,capture: :all_names) do
      [of, r1] ->
        o = integer(of)
        s = register(r1)
        <<43::6,s::5,t::5,o::16>>
      _ ->
        if Map.has_key?(ls, a1) do
          o = Map.get(ls, a1)
          <<43::6,t::10,o::16>>
        else
          throw {:mem_loc, a1}
        end
    end
  end
  # As la includes a label, it is split in 2 and later.
  def resolve_instruction(["la", r0, lb, <<code>>],ls) do
    <<h::16, l::16>> = if Map.has_key?(ls, lb) do
      <<Map.get(ls, lb)::32>>
    else
      throw {:label, lb}
    end
    t = register(r0)
    case code do
      0 -> <<15::6,1::10,h::16>>
      1 -> <<13::6,1::5,t::5,l::16>>
    end
  end
  def resolve_instruction([hd | instr],_), do: throw({:instr, hd <> " " <> Enum.join(instr, ", ")})


  ##############################################
  # Resolve a data declaration (string or int) #

  # Null terminated string #
  defp resolve_data(<<".asciiz ", rest::binary>>) do
    s_r = ~r/\A\"(?<s>[^"]*)\"\z/
    Regex.run(s_r, rest, capture: :all_names)
    |> case do
      [x] ->
        try do
          escape(x)
        catch
          :throw, invalid -> throw("#{rest} is not a valid string. Reason: #{invalid}.")
        end
        {:mem, <<x::bits,0::8>>}
      nil -> throw("'#{rest}' is not a valid string. Reason: Quote syntax incorrect.")
    end
  end

  # Regular string #
  defp resolve_data(<<".ascii ", rest::binary>>) do
    s_r = ~r/\A\"(?<s>[^"]*)\"\z/
    Regex.run(s_r, rest, capture: :all_names)
    |> case do
      [x] ->
        try do
          escape(x)
        catch
          :throw, invalid -> throw "#{rest} is not a valid string. Reason: #{invalid}."
        end
        {:mem, x}
      nil -> throw "'#{rest}' is not a valid string. Reason: Quote syntax incorrect."
    end
  end

  # 8 bits #
  defp resolve_data(<<".byte ", rest::binary()>>) do
    {:mem, String.split(rest, ", ")
    |> Enum.map(&
      try do
        case integer(&1) do
          x when x in 0..255 -> x
          x -> IO.warn("#{&1} truncated to 8 bits", []); x
        end
      catch
        _,_ -> throw "Invalid byte literal: #{&1}"
      end
    )
    |> Enum.into(<<>>, &<<&1::8>>)}
  end

  # 16 bits #
  defp resolve_data(<<".half ", rest::binary()>>) do
    {:mem, String.split(rest, ", ")
    |> Enum.map(&
      try do
        case integer(&1) do
          x when x in 0..65535 -> x
          x -> IO.warn("#{&1} truncated to 16 bits", []); x
        end
      catch
        _,_ -> throw "Invalid half literal: #{&1}"
      end
    )
    |> Enum.into(<<>>, &<<&1::16>>)}
  end

  # 32 bits #
  defp resolve_data(<<".word ", rest::binary()>>) do
    {:mem, String.split(rest, ", ")
    |> Enum.map(&
      try do
        case integer(&1) do
          x when x in 0..4294967295 -> x
          x -> IO.warn("#{&1} truncated to 32 bits", []); x
        end
      catch
        _,_ -> throw "Invalid word literal: #{&1}"
      end
    )
    |> Enum.into(<<>>, &<<&1::32>>)}
  end

  # Reserved space #
  defp resolve_data(<<".space ", rest::binary>>) do
    size = try do
      integer(rest)
      |> pow_2()
    catch
        _,_ -> throw "Invalid integer literal: #{rest}"
    end
    {:mem, <<0::size(size)>>}
  end

  # Align (resolved later) "
  defp resolve_data(<<".align ", rest::binary>>) do
    size = try do
      integer(rest)
      |> pow_2()
    catch
        _,_ -> throw "Invalid integer literal: #{rest}"
    end
    %{align: size}
  end


  ###########################################################################
  # Resolve a pseudo-instruction to the multiple instructions it represents #

  defp resolve_pseudo(["abs",r0,r1]), do: ["addu #{r0}, #{r1}, $0", "bgez #{r1}, 8", "sub #{r0}, #{r1}, $0"]
  defp resolve_pseudo(["blt",r0,r1, label]), do: ["slt $1, #{r0}, #{r1}", "bne $1, $0, #{label}"]
  defp resolve_pseudo(["bgt",r0,r1, label]), do: ["slt $1, #{r1}, #{r0}", "bne $1, $0, #{label}"]
  defp resolve_pseudo(["bge",r0,r1, label]), do: ["slt $1, #{r0}, #{r1}", "beq $1, $0, #{label}"]
  defp resolve_pseudo(["ble",r0,r1, label]), do: ["slt $1, #{r1}, #{r0}", "beq $1, $0, #{label}"]
  defp resolve_pseudo(["bltu",r0,r1, label]), do: ["sltu $1, #{r0}, #{r1}", "bne $1, $0, #{label}"]
  defp resolve_pseudo(["bgtu",r0,r1, label]), do: ["sltu $1, #{r1}, #{r0}", "bne $1, $0, #{label}"]
  defp resolve_pseudo(["bgeu",r0,r1, label]), do: ["sltu $1, #{r0}, #{r1}", "beq $1, $0, #{label}"]
  defp resolve_pseudo(["bleu",r0,r1, label]), do: ["sltu $1, #{r1}, #{r0}", "beq $1, $0, #{label}"]
  defp resolve_pseudo(["neg",r0,r1]), do: ["sub #{r0}, $0, #{r1}"]
  defp resolve_pseudo(["not",r0,r1]), do: ["xori #{r0}, #{r1}, 0xFFFF"]
  defp resolve_pseudo(["move",r0,r1]), do: ["add #{r0}, $0, #{r1}"]
  defp resolve_pseudo(["clear",r0]), do: ["lui #{r0}, 0"]
  defp resolve_pseudo(["sgt",r0,r1,r2]), do: ["slt #{r0}, #{r2}, #{r1}"]
  defp resolve_pseudo(["sge",r0,r1,r2]), do: ["slt #{r0}, #{r1}, #{r2}","xori #{r0}, #{r0}, 1"]
  defp resolve_pseudo(["sle",r0,r1,r2]), do: ["slt #{r0}, #{r2}, #{r1}","xori #{r0}, #{r0}, 1"]
  defp resolve_pseudo(["sgtu",r0,r1,r2]), do: ["sltu #{r0}, #{r2}, #{r1}"]
  defp resolve_pseudo(["sgeu",r0,r1,r2]), do: ["sltu #{r0}, #{r1}, #{r2}","xori #{r0}, #{r0}, 1"]
  defp resolve_pseudo(["sleu",r0,r1,r2]), do: ["sltu #{r0}, #{r2}, #{r1}","xori #{r0}, #{r0}, 1"]
  defp resolve_pseudo(["seq",r0,r1,r2]), do: ["xor #{r0}, #{r1}, #{r2}","sltiu #{r0}, #{r0}, 1"]
  defp resolve_pseudo(["sne",r0,r1,r2]), do: ["xori #{r0}, #{r1}, 0xFFFF","xor #{r0}, #{r2}, #{r0}","sltiu #{r0}, #{r0}, 0xFFFF"]
  defp resolve_pseudo(["li",r0,im]) do
    <<l::16,h::16>> = <<integer(im)::32>>
    ["lui $at, #{h}", "ori #{r0}, $at, #{l}"]
  end
  defp resolve_pseudo(["la",r0, label]), do: [<<"la #{r0}, #{label}, ", 0::8>>, <<"la #{r0}, #{label}, ", 1::8>>]
  defp resolve_pseudo([cmd, a0, a1, a2]), do: ["#{cmd} #{a0}, #{a1}, #{a2}"]
  defp resolve_pseudo([cmd, a0, a1]), do: ["#{cmd} #{a0}, #{a1}"]
  defp resolve_pseudo([cmd, a0]), do: ["#{cmd} #{a0}"]
  defp resolve_pseudo([cmd]), do: ["#{cmd}"]


  @doc """
  Resolve the instructions which will have a memory footprint different to 32, such as pseudo-instructions and data directives.
  """

  def resolve_early(op) do
    try do
      resolve_data(op)
    catch
      :throw, reason -> throw(reason)
      _,_ -> Regex.run(~r/\A(?<a>([^\s]+))(\s((?<ar0>([^,]+))(,\s(?<ar1>([^,]+))(,\s(?<ar2>([^,]+)))?)?)?)?\z/, op, capture: :all_names)
          |> Enum.reject(&""==&1)
          |> List.update_at(0, &String.downcase/1)
          |> resolve_pseudo()
    end
  end

  ##################################
  # Fast function to calculate 2^n #

  defp pow_2(0), do: 1
  defp pow_2(x), do: 2 * pow_2(x - 1)
end
