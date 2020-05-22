module Main exposing (main)

import Article
import Browser
import Debug
import Example
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Mosaic exposing (Mosaic)
import Ui



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \{ mosaic } -> Sub.map GotMosaicMsg (Mosaic.subscriptions mosaic)
        }



-- MODEL


type alias Model =
    { mosaic : Mosaic }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { mosaic =
            Mosaic.singleton
                --|> Mosaic.addArticle Example.html
                |> Mosaic.add_article "1"
                |> Mosaic.add_article "2"
                |> Mosaic.add_article "3"
                |> Mosaic.add_article "4"
                |> Mosaic.add_article "5"
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = GotMosaicMsg Mosaic.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotMosaicMsg m ->
            model.mosaic
                |> Mosaic.update m
                |> (\( mosaic, command ) ->
                        ( { model | mosaic = mosaic }
                        , Cmd.map GotMosaicMsg command
                        )
                   )



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ p []
            [ Html.text "Mosaic v0.0"
            , model.mosaic
                |> Mosaic.view
                |> Html.div [ class "mosaic" ]
                |> Html.map GotMosaicMsg

            --,
            --, Ui.button [class "fullwidth", onClick AddEditor] [Ui.icon "post_add"]
            --, Ui.button [class "fullwidth test", onClick AddEditor] [Ui.icon "post_add"]
            --, Ui.button [class "fullwidth", onClick AddEditor] [Ui.label "post_add"]
            ]
        ]
