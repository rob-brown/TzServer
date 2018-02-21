defmodule TzServer do
  def version, do: Tzdata.tzdata_version()

  def validate_timezone(name) do
    if Tzdata.zone_exists?(name) do
      :ok
    else
      {:error, :unknown_timezone}
    end
  end

  def all_zone_names do
    Tzdata.zone_list()
  end

  def all_dst_info do
    all_zone_names()
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
          %{start: process_dst_info(period2), end: process_dst_info(period1)}

        period2.std_off == 0 ->
          %{start: process_dst_info(period1), end: process_dst_info(period2)}
      end
    else
      _ ->
        [period | _] = Tzdata.periods_for_time(name, now_in_gregorian_seconds(), :utc)
        %{utc_off: period.utc_off}
    end
  end

  def all_periods(count) do
    all_zone_names()
    |> Stream.map(&{&1, periods(&1, count)})
    |> Map.new()
  end

  def periods(name, count, time \\ now_in_gregorian_seconds(), result \\ [])
  def periods(_name, 0, _time, result), do: Enum.reverse(result)

  def periods(name, count, time, result) when count > 0 do
    with [period = %{until: %{utc: utc}} | _] when utc != :max <-
           Tzdata.periods_for_time(name, time, :utc),
         one_day = 60 * 60 * 24,
         next_time = period.until.utc + one_day do
      periods(name, count - 1, next_time, [process_period(period) | result])
    else
      [%{until: %{utc: :max}, utc_off: utc_off, from: %{utc: from}, std_off: std_off} | _] ->
        [
          %{from: gregorian_to_unix(from), std_off: std_off, utc_off: utc_off}
          | Enum.reverse(result)
        ]
    end
  end

  defp now_in_gregorian_seconds do
    :calendar.universal_time() |> :calendar.datetime_to_gregorian_seconds()
  end

  defp process_dst_info(period = %{from: %{utc: from}, until: %{utc: until}}) do
    %{period | from: gregorian_to_unix(from), until: gregorian_to_unix(until)}
  end

  defp process_period(%{
         from: %{utc: from},
         until: %{utc: until},
         std_off: std_off,
         utc_off: utc_off
       }) do
    %{
      from: gregorian_to_unix(from),
      until: gregorian_to_unix(until),
      std_off: std_off,
      utc_off: utc_off
    }
  end

  defp gregorian_to_unix(:min) do
    0
  end

  defp gregorian_to_unix(gregorian) do
    gregorian - 62_167_219_200
  end
end
