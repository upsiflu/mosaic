module Article exposing
    (  Appearance(..)
       -- create

    , Article
    , Caret
    , Draft
    , Format
    , Msg(..)
    , singleton
    , update
    , view
    )

import Html exposing (Html, div, pre, span, strong, text)
import Html.Attributes exposing (attribute, class)
import Html.Events exposing (on, onBlur, onDoubleClick)
import Json.Decode as Decode exposing (Decoder, list, string)
import Json.Decode.Pipeline exposing (requiredAt)
import Tile
import Ui exposing (..)


type alias Article =
    -- the text that the vDOM thinks is current:
    { release : Release

    -- the most recent formatting command:
    , format : Format

    -- the text that the user is actually editing:
    , draft : Draft
    , caret : Caret
    }


type Caret
    = Caret (List String)


type alias Format =
    String


type Draft
    = Draft String


type alias Release =
    String



-- generate


singleton : String -> Article
singleton s =
    { release = s
    , format = ""
    , draft = Draft s
    , caret = Caret []
    }



{-

   got : Tile.Message -> Article -> Article
   got message article =
       case ( message, article.editing ) of
           ( Tile.WalkedAway, True ) ->
               { article | editing = False
                         , release = article.draft |> \(Draft string) -> string
               }
           ( Tile.WalkedHere, False ) ->
               { article | editing = True }

           _ -> article
-}


type Msg
    = DraftChanged Draft
    | CaretChanged Caret
    | FormatIssued Format
    | GotTileMsg Tile.Msg





update : Msg -> Article -> Article
update msg article =
    case msg of
        DraftChanged new ->
            { article | draft = new }

        CaretChanged new ->
            { article | caret = new }

        FormatIssued new ->
            { article | format = new |> Debug.log "Format at Article" }

        GotTileMsg m ->
            article



{-
   GotTileMessage message ->
       case ( message, article.editing ) of
           ( Tile.WalkedAway, True ) ->
               { article
                   | editing = False
                   , release = article.draft |> \(Draft string) -> string
               }
           ( Tile.WalkedHere, False ) ->
               { article
                   | editing = True
               }
           _ -> article

-}
-- decoders


draftDecoder : Decoder Draft
draftDecoder =
    Decode.succeed Draft
        |> requiredAt [ "detail", "draft" ] string


caretDecoder : Decoder Caret
caretDecoder =
    Decode.succeed Caret
        |> requiredAt [ "detail", "caret" ] (list string)


type Appearance msg
    = Normal
    | Selected
    | Editor (Msg -> msg)



-- Mosaic constructs the Appearance viewModel.


view : Appearance msg -> Article -> Ui msg
view appearance article =
    let
        decodeOn event decoder message =
            decoder
                |> Decode.map message
                |> on event

        toolbar_placeholder =
            div [ class "toolbar " ] []
    in
    case appearance of
        Normal ->
            Ui.Static
                [ toolbar_placeholder
                , Html.node "custom-editor"
                    [ attribute "release" article.release
                    , attribute "format" article.format
                    , attribute "state" "done"
                    ]
                    []
                ]

        Selected ->
            Ui.Static
                [ toolbar_placeholder
                , Html.node "custom-editor"
                    [ attribute "release" article.release
                    , attribute "format" article.format
                    , attribute "state" "done"
                    ]
                    []
                ]

        Editor how_to_message ->
            Ui.Active
                [ viewToolbar (FormatIssued >> how_to_message) article.caret
                , Html.node "custom-editor"
                    [ attribute "release" article.release
                    , attribute "format" article.format
                    , attribute "state" "editing"
                    , decodeOn "draft" draftDecoder (DraftChanged >> how_to_message)
                    , decodeOn "caret" caretDecoder (CaretChanged >> how_to_message)
                    ]
                    []
                ]


viewToolbar : (Format -> msg) -> Caret -> Html msg
viewToolbar on_format (Caret caret) =
    let
        is_in : List a -> a -> Bool
        is_in l a =
            List.member a l

        toggle : String -> String -> String -> Ui.Face -> Ui.Option msg
        toggle command revert match face =
            face
                |> Ui.Toggle
                |> (\needs_toggle_and_is_on -> decideState command revert match |> needs_toggle_and_is_on)

        decideState on off =
            is_in caret
                >> (\activated ->
                        { toggle =
                            on_format
                                (if activated then
                                    off

                                 else
                                    on
                                )
                        , is_on = activated
                        }
                   )
    in
    [ Ui.icon "Numbered list" "format_list_numbered" |> toggle "makeOrderedList" "removeList" "OL"
    , Ui.icon "List with bullet points" "format_list_bulleted" |> toggle "makeUnorderedList" "removeList" "UL"
    , Ui.icon "Decrease Level" "format_indent_decrease" |> toggle "decreaseLevel" "increaseListLevel" "neverj"
    , Ui.icon "Increase Level" "format_indent_increase" |> toggle "increaseLevel" "decreaseListLevel" "never"
    , Ui.preview "Title" "h1" [ Ui.text "Title" ] |> toggle "makeTitle" "removeHeader" "H1"
    , Ui.preview "Chapter Heading" "h2" [ Ui.text "Heading" ] |> toggle "makeHeader" "removeHeader" "H2"
    , Ui.preview "Secondary Heading" "h3" [ Ui.text "Secondary" ] |> toggle "makeSubheader" "removeHeader" "H3"
    , Ui.preview "Strong emphasis" "T b" [ Ui.text "B" ] |> toggle "bold" "removeBold" "b"
    , Ui.preview "Emphasis" "T i" [ Ui.text "I" ] |> toggle "italic" "removeItalic" "i"
    , Ui.icon "Clear formatting" "format_clear" |> toggle "removeAllFormatting" "" "?"
    , Ui.icon "Hyperlink" "link" |> toggle "addLink" "removeLink" "a"
    , Ui.icon "Clear hyperlink" "link_off" |> toggle "removeLink" "" "?"
    ]
        |> Ui.viewToolbar "paragraph-style"
