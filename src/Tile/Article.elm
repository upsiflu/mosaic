module Tile.Article exposing
    ( Article
    , Caret
    , Draft
    , Format
    , Msg(..)
    , singleton
    , update
    , view
    )


{-|
@docs Article,singleton

# Data
@docs Caret, Draft, Format

# Update
@docs Msg, update

# View
@docs view
-}

import W3.Html exposing (Event, node, on, div, text, keyed)
import W3.Html.Attributes exposing (attribute, class)
import Json.Decode as Decode exposing (list, string)
import Json.Decode.Pipeline exposing (requiredAt)
import Tile.General
import Gui

{-|-}
type alias Article =
    { release : Release
    , format : Format
    , draft : Draft
    , caret : Caret
    }


{-| The text that the vDOM thinks is current (sent to JS through view).
-}
type Caret
    = Caret (List String)

{-| The most recent formatting command (sent to JS through view).
-}
type alias Format =
    String

{-| The text that the user is actually editing (received from JS).
-}
type Draft
    = Draft String

type alias Release =
    String

{-|-}
singleton : String -> Article
singleton s =
    { release = s
    , format = ""
    , draft = Draft s
    , caret = Caret []
    }

{-|-}
type Msg
    = DraftChanged Draft
    | CaretChanged Caret
    | FormatIssued Format
    | GotTileMsg Tile.General.Msg

{-|-}
update : Msg -> Article -> Article
update msg article =
    case msg of
        DraftChanged new ->
            { article | draft = new }

        CaretChanged new ->
            { article | caret = new }

        FormatIssued new ->
            { article | format = new }

        GotTileMsg _ ->
            article




{-| Mosaic constructs the `Appearance` viewModel. -}
view : Tile.General.Appearance (Msg -> msg) -> Article -> Gui.Document { mode | expanded : Gui.Mode, collapsed : Gui.Mode } msg
view appearance article =
    let
        face = Gui.icon "Article" "text_fields"

        toolbar_placeholder =
            div [ class ["toolbar"] ] []

        propagate key shape message decoder =
            requiredAt [ "detail", key ] decoder ( Decode.succeed shape )
                |> Decode.map (\result -> Event (message result) False False)
                |> on key

    in
    case appearance of
        Tile.General.Normal ->
            Gui.collapsed_document face []
                [ toolbar_placeholder
                , node "custom-editor"
                    [ attribute "release" article.release
                    , attribute "format" article.format
                    , attribute "state" "done"
                    ]
                    [] |> Debug.log ("normal custom editor node ("++article.release++")")
                ]

        Tile.General.Selected ->
            Gui.collapsed_document face []
                [ toolbar_placeholder
                , node "custom-editor"
                    [ attribute "release" article.release
                    , attribute "format" article.format
                    , attribute "state" "done"
                    ]
                    [] |> Debug.log ("selected or focused custom editor node ("++article.release++")")
                ]

        Tile.General.Editor how_to_message ->
            Gui.expanded_document face []
                [ node "custom-editor"
                    [ attribute "release" article.release
                    , attribute "format" article.format
                    , attribute "state" "editing"
                    , propagate "draft" Draft ( DraftChanged >> how_to_message ) string
                    , propagate "caret" Caret ( CaretChanged >> how_to_message ) (list string)
                    ]
                    [] |> Debug.log ("editing custom editor node ("++article.release++")")
                ]
            |> Gui.with_toolbar (toolbar (FormatIssued >> how_to_message) article.caret)


toolbar : (Format -> msg) -> Caret -> Gui.Toolbar msg
toolbar on_format (Caret caret) =
    let
        is_in : List a -> a -> Bool
        is_in l a =
            List.member a l

        toggle : String -> String -> String -> Gui.Face msg -> Gui.Control msg
        toggle command revert match face =
            face
                |> Gui.Toggle
                |> (\needs_toggle_and_is_on -> decide_state command revert match |> needs_toggle_and_is_on)

        decide_state on off =
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
    [ Gui.icon "Numbered list" "format_list_numbered" 
        |> toggle "makeOrderedList" "removeList" "OL"
    , Gui.icon "List with bullet points" "format_list_bulleted" 
        |> toggle "makeUnorderedList" "removeList" "UL"
    , Gui.icon "Decrease Level" "format_indent_decrease" 
        |> toggle "decreaseLevel" "increaseListLevel" "neverj"
    , Gui.icon "Increase Level" "format_indent_increase" 
        |> toggle "increaseLevel" "decreaseListLevel" "never"
    , Gui.sample "Title" "h1" [ text "Title" ] 
        |> toggle "makeTitle" "removeHeader" "H1"
    , Gui.sample "Chapter Heading" "h2" [ text "Heading" ] 
        |> toggle "makeHeader" "removeHeader" "H2"
    , Gui.sample "Secondary Heading" "h3" [ text "Secondary" ] 
        |> toggle "makeSubheader" "removeHeader" "H3"
    , Gui.sample "Strong emphasis" "T b" [ text "B" ] 
        |> toggle "bold" "removeBold" "b"
    , Gui.sample "Emphasis" "T i" [ text "I" ] 
        |> toggle "italic" "removeItalic" "i"
    , Gui.icon "Clear formatting" "format_clear" 
        |> toggle "removeAllFormatting" "" "?"
    , Gui.icon "Hyperlink" "link" 
        |> toggle "addLink" "removeLink" "a"
    , Gui.icon "Clear hyperlink" "link_off" 
        |> toggle "removeLink" "" "?"
    ]
    |> Gui.toolbar 
        ( Gui.literal "❦" |> Gui.with_hint "Formatting" )
