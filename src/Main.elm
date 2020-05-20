module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Ui

import Example

import Article
import Mosaic exposing (Mosaic)

import Debug




-- MAIN


main : Program () Model Msg
main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = \{ mosaic } -> Sub.map GotMosaicMsg ( Mosaic.subscriptions mosaic )
    }




-- MODEL


type alias Model =
  { mosaic : Mosaic }



init : () -> ( Model, Cmd Msg )
init _ =
  ( { mosaic = 
      Mosaic.singleton 
      --|> Mosaic.addArticle Example.html 
      |> Mosaic.addArticle "1" 
      |> Mosaic.addArticle "2" 
      |> Mosaic.addArticle "3" 
      |> Mosaic.addArticle "4" 
      |> Mosaic.addArticle "5"
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
        |> \(mosaic, command) ->
              ( { model | mosaic = mosaic }
              , Cmd.map GotMosaicMsg command )



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ p []
        [ Html.text "Mosaic v0.0"
        , model.mosaic
          |> Mosaic.view
          |> Html.map GotMosaicMsg
      --, 
      --, Ui.button [class "fullwidth", onClick AddEditor] [Ui.icon "post_add"]
      --, Ui.button [class "fullwidth test", onClick AddEditor] [Ui.icon "post_add"]
      --, Ui.button [class "fullwidth", onClick AddEditor] [Ui.label "post_add"]
       
      ]
    ]


