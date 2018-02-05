defmodule TzServer do
  def version, do: Tzdata.tzdata_version()

  def validate_timezone(name) do
    if Tzdata.zone_exists?(name) do
      :ok
    else
      {:error, :unknown_timezone}
    end
  end

  def all_dst_info() do
    Tzdata.zone_list()
    |> Stream.map(&{&1, dst_info(&1)})
    |> Map.new()
  end

  def dst_info(name) do
    with time = now_in_gregorian_seconds(),
         [period1 = %{until: %{utc: utc}} | _] when utc != :max <-
           Tzdata.periods_for_time(name, time, :utc),
         one_day = 60 * 60 * 24,
         next_time = period1.until.utc + one_day,
         [period2 | _] <- Tzdata.periods_for_time(name, next_time, :utc) do
      cond do
        period1.std_off == 0 ->
          %{start: process(period2), end: process(period1)}

        period2.std_off == 0 ->
          %{start: process(period1), end: process(period2)}
      end
    else
      _ ->
        [period | _] = Tzdata.periods_for_time(name, now_in_gregorian_seconds(), :utc)
        %{utc_off: period.utc_off}
    end
  end

  defp now_in_gregorian_seconds do
    :calendar.universal_time() |> :calendar.datetime_to_gregorian_seconds()
  end

  defp process(period = %{from: from, until: until}) do
    %{period | from: process(from), until: process(until)}
  end

  defp process(%{utc: utc, wall: wall, standard: standard}) do
    %{
      utc: gregorian_to_unix(utc),
      wall: gregorian_to_unix(wall),
      standard: gregorian_to_unix(standard)
    }
  end

  defp gregorian_to_unix(gregorian) do
    gregorian - 62_167_219_200
  end
end
