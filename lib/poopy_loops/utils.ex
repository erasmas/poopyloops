defmodule PoopyLoops.Utils do
  def ulid_to_uuid(ulid_string) do
    case Ecto.ULID.cast(ulid_string) do
      {:ok, _} ->
        case Ecto.ULID.dump(ulid_string) do
          {:ok, binary} ->
            binary
            |> :binary.bin_to_list()
            |> Enum.map(&(Integer.to_string(&1, 16) |> String.pad_leading(2, "0")))
            |> Enum.chunk_every(4, 4, :discard)
            |> Enum.map(&Enum.join(&1, ""))
            |> Enum.join("-")

          :error ->
            {:error, "Failed to dump ULID"}
        end

      :error ->
        {:error, "Invalid ULID"}
    end
  end
end
