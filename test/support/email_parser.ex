defmodule TdAudit.EmailParser do
  @moduledoc """
  Module for helper functions parsing email HTML
  """

  def parse_layout(document) do
    [
      {"html", _,
       [
         {"head", _, _},
         {"body", _,
          [
            {"table", _,
             [
               {"tbody", _,
                [
                  {"tr", _,
                   [
                     {"td", _,
                      [
                        {"table", _,
                         [
                           {"tbody", _,
                            [
                              {"tr", _,
                               [
                                 {"td", _, [_header]}
                               ]}
                            ]}
                         ]}
                      ]}
                   ]},
                  {"tr", _, [{"td", _, content}]},
                  {"tr", _,
                   [
                     {"td", _,
                      [
                        {"table", _,
                         [
                           {"tbody", _,
                            [
                              {"tr", _,
                               [
                                 {"td", _, [_footer]}
                               ]}
                            ]}
                         ]}
                      ]}
                   ]}
                ]}
             ]}
          ]}
       ]}
    ] = document

    content
  end

  def parse_events(events) do
    events
    |> Enum.map(&parse_event/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_event(text) when is_binary(text), do: nil
  defp parse_event({"div", _, [event]}), do: parse_event(event)

  defp parse_event(event) do
    {"table", _,
     [
       {"tbody", _,
        [
          {"tr", _, [{"td", _, _}]},
          {"tr", _,
           [
             {"td", _,
              [
                {"table", _,
                 [
                   {"tbody", _,
                    [
                      {"tr", _,
                       [
                         {"td", _,
                          [
                            {"span", _,
                             [
                               {"a", [{"href", link}, _], header}
                             ]}
                          ]}
                       ]}
                    ]}
                 ]}
              ]}
           ]},
          {"tr", _, [{"td", _, [{"table", _, [{"tbody", _, content}]}]}]},
          {"tr", _, [{"td", _, _}]}
        ]}
     ]} = event

    {link, parse_header(header), parse_event_content(content)}
  end

  defp parse_event_content(content) do
    Enum.map(content, fn
      {"tr", _,
       [
         {"th", _, [key]},
         {"td", _, [value]}
       ]} ->
        {String.trim(key), String.trim(value)}

      {"tr", _,
       [
         {"th", _, [key]},
         {"td", _, []}
       ]} ->
        {String.trim(key), nil}

      {"tr", _, [text]} when is_binary(text) ->
        String.trim(text)

      {"tr", _, [{"th", _, [{"b", _, [text]}]}]} ->
        String.trim(text)

      _ ->
        raise "Error parsing invalid event row"
    end)
  end

  defp parse_header([header]) when is_binary(header), do: String.trim(header)
  defp parse_header(_), do: nil
end
