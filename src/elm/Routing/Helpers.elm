module Routing.Helpers exposing (..)

import Navigation exposing (Location)
import UrlParser as Url exposing ((</>))


type Route
    = HomeRoute
    | SettingsRoute
    | NotFoundRoute


reverseRoute : Route -> String
reverseRoute route =
    case route of
        SettingsRoute ->
            "/settings"

        _ ->
            "/"


routeParser : Url.Parser (Route -> a) a
routeParser =
    Url.oneOf
        [ Url.map HomeRoute Url.top
        , Url.map SettingsRoute (Url.s "settings")
        ]


parseLocation : Location -> Route
parseLocation location =
    location
        |> Url.parsePath routeParser
        |> Maybe.withDefault NotFoundRoute
