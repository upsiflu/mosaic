module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Extra as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mosaic exposing (Mosaic)
import Example



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \mosaic -> Sub.map GotMosaicMsg (Mosaic.subscriptions mosaic)
        }



-- MODEL


type alias Model =
    Mosaic


init : () -> ( Model, Cmd Msg )
init _ =
    ( Mosaic.singleton
                --|> Mosaic.add_article Example.html
                |> Mosaic.add_article "Article Number 1"
                |> Mosaic.add_article "Article Number 2"
                |> Mosaic.add_article "Article Number 3"
                |> Mosaic.add_article "Article Number 4"
                |> Mosaic.add_article "Article Number 5"
    , Cmd.none
    )



-- UPDATE


type Msg
    = GotMosaicMsg Mosaic.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotMosaicMsg m ->
            model
                |> Mosaic.update m
                |> (\( mosaic, command ) ->
                        ( mosaic
                        , Cmd.map GotMosaicMsg command
                        )
                   )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ p []
            [ Html.text "Mosaic v0.0"
            , model
                |> Mosaic.view
                |> Html.div ( class "mosaic" :: Mosaic.offset model )
                |> Html.map GotMosaicMsg

            --,
            --, Ui.button [class "fullwidth", onClick AddEditor] [Ui.icon "post_add"]
            --, Ui.button [class "fullwidth test", onClick AddEditor] [Ui.icon "post_add"]
            --, Ui.button [class "fullwidth", onClick AddEditor] [Ui.label "post_add"]
            ]
        ]
