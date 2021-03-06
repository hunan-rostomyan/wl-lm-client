module Main exposing (main)

import Json.Decode exposing (..)
import Json.Encode exposing (..)
import Http exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, keyCode)
import Navigation exposing (Location)
import UrlParser exposing ((</>))
import Bootstrap.Navbar as Navbar
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Form.Input as Input
import Bootstrap.Button as Button


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { view = view
        , update = update
        , subscriptions = subscriptions
        , init = init
        }


type alias Model =
    { page : Page
    , navState : Navbar.State
    , text : String
    , perplexities : List Float
    , nextWordList: List String
    }


type Page
    = Home
    | NotFound
    | EvaluatePage
    | NextWordsPage


init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( navState, navCmd ) =
            Navbar.initialState NavMsg

        ( model, urlCmd ) =
            urlUpdate location { navState = navState
                               , page = Home
                               , text = ""
                               , perplexities = []
                               , nextWordList = []
                               }
    in
        ( model, Cmd.batch [ urlCmd, navCmd ] )


type Msg
    = UrlChange Location
    | NavMsg Navbar.State
    | TextChange String
    | Evaluate
    | Next
    | EvaluationResult (Result Http.Error String)
    | NextResult (Result Http.Error String)
    | EvaluateSubmit
    | NextSubmit



onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.Decode.succeed msg
            else
                Json.Decode.fail "not ENTER"
    in
        Html.Events.on "keydown" (Json.Decode.andThen isEnter keyCode)


evaluateText : String -> Cmd Msg
evaluateText text =
    let 
        body =
            (Http.jsonBody
                (Json.Encode.object
                    [ ( "text", Json.Encode.string text )
                    ]
                )
            )
    in
        Http.post "http://127.0.0.1:7777/eval/" body (Json.Decode.string)
            |> Http.send EvaluationResult


next : String -> Cmd Msg
next text =
    let 
        body =
            (Http.jsonBody
                (Json.Encode.object
                    [ ( "text", Json.Encode.string text )
                    ]
                )
            )
    in
        Http.post "http://127.0.0.1:7777/next/" body (Json.Decode.string)
            |> Http.send NextResult


subscriptions : Model -> Sub Msg
subscriptions model =
    Navbar.subscriptions model.navState NavMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            urlUpdate location model

        NavMsg state ->
            ( { model | navState = state }
            , Cmd.none
            )

        Evaluate ->
            ( model, evaluateText model.text )

        Next ->
            ( model, next model.text)

        TextChange newText ->
            ( { model | text = newText }
            , Cmd.none
            )

        EvaluateSubmit ->
            update Evaluate model

        NextSubmit ->
            update Next model

        EvaluationResult (Ok str) ->
            case decodeString (Json.Decode.list Json.Decode.float) str of
                Ok lst -> ({ model | perplexities = lst }, Cmd.none)
                Err _ -> ({ model | perplexities = [-1] }, Cmd.none)

        EvaluationResult (Err err) ->
            let
                log = (Debug.log "Error evaluating sentence." err)
            in
                ({ model | perplexities = [-1] }, Cmd.none)

        NextResult (Ok str) ->
            case decodeString (Json.Decode.list Json.Decode.string) str of
                Ok lst -> ({ model | nextWordList = lst }, Cmd.none)
                Err _ -> ({ model | nextWordList = [] }, Cmd.none)

        NextResult (Err err) ->
            let
                log = (Debug.log "Error getting the next word list." err)
            in
                ({ model | nextWordList = [] }, Cmd.none)


urlUpdate : Navigation.Location -> Model -> ( Model, Cmd Msg )
urlUpdate location model =
    case decode location of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just route ->
            ( { model | page = route }, Cmd.none )


decode : Location -> Maybe Page
decode location =
    UrlParser.parseHash routeParser location


routeParser : UrlParser.Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map Home UrlParser.top
        , UrlParser.map EvaluatePage (UrlParser.s "evaluate")
        , UrlParser.map NextWordsPage (UrlParser.s "next")
        ]


view : Model -> Html Msg
view model =
    div []
        [ menu model
        , mainContent model
        ]


menu : Model -> Html Msg
menu model =
    Navbar.config NavMsg
        |> Navbar.withAnimation
        |> Navbar.brand [ href "#" ] [ text "LM Client" ]
        |> Navbar.attrs [ class "container-fullwidth" ]
        |> Navbar.items
            [ Navbar.itemLink [ href "#evaluate" ] [ text "Evaluate" ]
            , Navbar.itemLink [ href "#next" ] [ text "Next Word" ]
            ]
        |> Navbar.view model.navState


mainContent : Model -> Html Msg
mainContent model =
    Grid.containerFluid [ class "main" ] <|
        case model.page of
            Home ->
                pageHome model

            NotFound ->
                pageNotFound

            EvaluatePage ->
                pageEvaluate model

            NextWordsPage ->
                pageNextWords model


perplexitiesView : Model -> List (Html Msg)
perplexitiesView model =
    [ text (toString (List.head model.perplexities |> Maybe.withDefault -1.0 )) ]


nextWordView : Model -> List (Html Msg)
nextWordView model =
    [ ul [] (List.map (\word -> li [] [ text word ]) model.nextWordList) ]


pageHome : Model -> List (Html Msg)
pageHome model =
    [ div [] [ text "Available functions" ]
    , ul []
        [ li [] [ a [ href "#evaluate" ] [ text "Text -> Perplexity" ] ]
        , li [] [ a [ href "#next" ] [ text "Text -> Next Word" ] ]
        ]
    ]


pageEvaluate : Model -> List (Html Msg)
pageEvaluate model =
    [ h5 [] [ text "Text -> Perplexity" ]
    , Grid.row []
        [ Grid.col []
            [ Input.text [ Input.id "text", Input.attrs [ onEnter EvaluateSubmit, onInput TextChange ] ]
            , Button.button
                [ Button.primary
                , Button.attrs [ onClick Evaluate ]
                ]
                [ text "Evaluate" ]
            ]
        , Grid.col [ Col.attrs [ class "perplexities" ] ] (perplexitiesView model)
        ]
    ]


pageNextWords : Model -> List (Html Msg)
pageNextWords model = 
    [ h5 [] [ text "Text -> Next Word" ]
    , Grid.row []
        [ Grid.col []
            [ Input.text [ Input.id "text", Input.attrs [ onEnter NextSubmit, onInput TextChange ] ]
            , Button.button
                [ Button.primary
                , Button.attrs [ onClick Next ]
                ]
                [ text "Compute" ]
            ]
        , Grid.col [ Col.attrs [ class "nextWordList" ] ] (nextWordView model)
        ]
    ]


pageNotFound : List (Html Msg)
pageNotFound =
    [ h1 [] [ text "Not found" ]
    , text "Sorry couldn't find that page"
    ]
