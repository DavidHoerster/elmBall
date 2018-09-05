module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D exposing (Decoder, decodeString, field, int, list, map2, string)
import Url
import Url.Parser as Parser exposing ((</>), Parser, custom, fragment, map, oneOf, s, string, top)



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type Page
    = NotFound
    | PlayerSearch String
    | PlayerSearchResults (List Player)
    | PlayerDetails String (List PlayerDetail)
    | GameSearch String
    | Dashboard
    | Help


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , page : Page
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key url Dashboard, Cmd.none )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | RunSearch String
    | SearchChange String
    | OnSearchResults (Result Http.Error (List Player))
    | GetPlayerDetails String
    | OnPlayerDetailResults (Result Http.Error (List PlayerDetail))
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            parseUrl url model

        SearchChange q ->
            ( { model | page = PlayerSearch q }, Cmd.none )

        RunSearch q ->
            ( model
            , Http.send OnSearchResults (Http.get ("/api/search/" ++ q) (list playerDecoder))
            )

        OnSearchResults result ->
            case result of
                Ok players ->
                    ( { model | page = PlayerSearchResults players }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        GetPlayerDetails id ->
            ( model
            , Http.send OnPlayerDetailResults (Http.get ("/api/player/" ++ id) (list playerDetailDecoder))
            )

        OnPlayerDetailResults result ->
            case result of
                Ok details ->
                    ( { model | page = PlayerDetails "fake" details }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )



-- JSON


type alias Player =
    { name : String
    , playerId : String
    }


type alias PlayerDetail =
    { name : String
    , playerId : String
    , bbrefId : String
    , yearId : Int
    , hits : Int
    , homeRuns : Int
    , runsBattedIn : Int
    }


playerDecoder : Decoder Player
playerDecoder =
    map2 Player
        (field "name" D.string)
        (field "playerId" D.string)


playerDetailDecoder : Decoder PlayerDetail
playerDetailDecoder =
    D.map7 PlayerDetail
        (field "name" D.string)
        (field "playerId" D.string)
        (field "bbrefId" D.string)
        (field "yearId" D.int)
        (field "hits" D.int)
        (field "homeRuns" D.int)
        (field "runsBattedIn" D.int)



-- PARSER


parseUrl : Url.Url -> Model -> ( Model, Cmd Msg )
parseUrl url model =
    let
        parser =
            oneOf
                [ route top ( { model | page = Dashboard }, Cmd.none )

                -- , route (s "player" </> s "search" </> Parser.string) (\name -> ({model | page = PlayerSearchResults name}, Cmd.none))
                , route (s "player" </> s "search") ( { model | page = PlayerSearch "" }, Cmd.none )
                , route (s "player" </> Parser.string) (\name -> ( { model | page = PlayerDetails name [] }, Cmd.none ))
                , route (s "game" </> Parser.string) (\id -> ( { model | page = GameSearch id }, Cmd.none ))
                , route (s "dashboard") ( { model | page = Dashboard }, Cmd.none )
                , route (s "help") ( { model | page = Help }, Cmd.none )
                ]
    in
    case Parser.parse parser url of
        Just answer ->
            answer

        Nothing ->
            ( { model | page = NotFound }, Cmd.none )


route : Parser a b -> a -> Parser (b -> c) c
route parser handler =
    Parser.map handler parser



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.page of
        NotFound ->
            { title = "Baseball Stuff"
            , body =
                [ text "Sorry, can't find that page" ]
            }

        PlayerSearch q ->
            { title = "Baseball Stuff"
            , body =
                [ viewSearch q ]
            }

        PlayerSearchResults players ->
            { title = "Baseball Stuff"
            , body =
                [ viewResults players ]
            }

        PlayerDetails id details ->
            { title = "Baseball Stuff"
            , body =
                [ viewPlayerDetails id details ]
            }

        GameSearch id ->
            { title = "Baseball Stuff"
            , body =
                [ text ("Let's search for game " ++ id) ]
            }

        Help ->
            { title = "Baseball Stuff"
            , body =
                [ text "How can I help you?" ]
            }

        Dashboard ->
            { title = "Baseball Stuff"
            , body =
                [ viewDash ]
            }



-- VIEW PLAYER DETAILS


viewPlayerDetails : String -> List PlayerDetail -> Html Msg
viewPlayerDetails id details =
    div []
        [ h2 [] [ text ("Player Details for " ++ id) ]
        , viewDetails details
        ]


viewDetails : List PlayerDetail -> Html Msg
viewDetails details =
    table [ class "table" ]
        [ thead []
            [ th [] [ text "Year" ]
            , th [] [ text "Name" ]
            , th [] [ text "Player ID" ]
            , th [] [ text "Hits" ]
            , th [] [ text "Home Runs" ]
            , th [] [ text "Runs Batted In" ]
            ]
        , tbody [] (List.map viewDetail details)
        ]


viewDetail : PlayerDetail -> Html Msg
viewDetail detail =
    tr []
        [ td [] [ text (String.fromInt detail.yearId) ]
        , td [] [ text detail.name ]
        , td [] [ text detail.playerId ]
        , td [] [ text (String.fromInt detail.hits) ]
        , td [] [ text (String.fromInt detail.homeRuns) ]
        , td [] [ text (String.fromInt detail.runsBattedIn) ]
        ]



-- VIEW SEARCH RESULTS


viewResults : List Player -> Html Msg
viewResults players =
    div [ class "content" ]
        [ h2 [] [ text "Search Results" ]
        , viewPlayers players
        ]


viewPlayers : List Player -> Html Msg
viewPlayers players =
    ul [] (List.map viewLinkForPlayer players)


viewLinkForPlayer : Player -> Html Msg
viewLinkForPlayer player =
    li [] [ a [ href ("/player/" ++ player.playerId), onClick (GetPlayerDetails player.playerId) ] [ text player.name ] ]


viewSearch : String -> Html Msg
viewSearch searchString =
    div []
        [ text "Name: "
        , input [ placeholder "Partial player name", value searchString, onInput SearchChange ] []
        , button [ onClick (RunSearch searchString) ] [ text "Go!" ]
        ]



-- VIEW DASHBOARD


viewDash : Html Msg
viewDash =
    ul []
        [ viewLink "/help" "Get Help"
        , viewLink "/dashboard" "Go Home"
        , viewLink "/player/dave" "Get Info on Dave"
        , viewLink "/player/search" "Do a Search"
        , viewLink "/game/world-series" "Get Info on the World Series"
        ]


viewLink : String -> String -> Html msg
viewLink path display =
    li [] [ a [ href path ] [ text display ] ]
