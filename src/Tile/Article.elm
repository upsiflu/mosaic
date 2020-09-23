module Tile.Article exposing
    ( Article, singleton
    , update
    , view
    , Msg
    )

{-|

@docs Article, singleton


# Data types

@docs Caret, Draft, Format


# Update

@docs Msg, update


# View

@docs view

-}

import Gui
import Json.Decode as Decode exposing (index, int, list, map2, string)
import Json.Decode.Pipeline exposing (requiredAt)
import Tile.Interface
import W3.Html exposing (Event, div, node, on, text)
import W3.Html.Attributes exposing (attribute, class)


{-| -}
type alias Article =
    -- Shadows (state held by the JS cusom element)
    { draft : Draft
    , caret : Caret
    , size : Vector
    , delta : Vector

    -- Attributes (state held by Elm)
    , release : Release
    , format : Format
    }


{-| -}
singleton : String -> Article
singleton s =
    -- Events
    { draft = Draft s
    , caret = Caret []
    , size = Vector ( 0, 0 )
    , delta = Vector ( 0, 0 )

    -- Attributes
    , release = s
    , format = ""
    }



-- Shadows


{-| The text that the user is actually editing (received from JS)
-}
type Draft
    = Draft String


{-| Active formats under the current cursor
-}
type Caret
    = Caret (List String)


{-| -}
type Vector
    = Vector ( Int, Int )


vector =
    map2 Tuple.pair (index 0 int) (index 1 int)



-- Attributes


{-| The most recent formatting command (sent to JS through view)
-}
type alias Format =
    String


type alias Release =
    String


{-| -}
type
    Msg
    -- Events
    = DraftChanged Draft
    | CaretChanged Caret
    | SizeChanged Vector
    | DeltaChanged Vector
    | Pressed Vector
    | Tapped Vector
    | Grabbed Vector
    | Dropped Vector
      -- Attributes
    | FormatIssued Format
    | GotTileMsg Tile.Interface.Msg


{-| -}
update : Msg -> Article -> Article
update msg article =
    case msg of
        -- Events
        DraftChanged new ->
            { article | draft = new }

        CaretChanged new ->
            { article | caret = new }

        SizeChanged new ->
            { article | size = new }

        DeltaChanged new ->
            { article | delta = new }

        Pressed point ->
            article

        Tapped point ->
            article

        Grabbed point ->
            article

        Dropped point ->
            article

        -- Attributes
        FormatIssued new ->
            { article | format = new }

        GotTileMsg _ ->
            article


{-| Mosaic constructs the `Appearance` viewModel.
-}
view : Tile.Interface.Appearance (Msg -> msg) -> Article -> Gui.Document { mode | expanded : Gui.Mode, collapsed : Gui.Mode } msg
view appearance article =
    let
        face =
            Gui.icon "Article" "text_fields"

        toolbar_placeholder =
            div [ class [ "toolbar" ] ] []

        propagate key shape message decoder =
            requiredAt [ "detail", key ] decoder (Decode.succeed shape)
                |> Decode.map (\result -> Event (message result) False False)
                |> on key
    in
    case appearance of
        Tile.Interface.Normal ->
            Gui.collapsed_document face
                []
                [ toolbar_placeholder
                , node "custom-editor"
                    [ attribute "state" "done"
                    , attribute "release" article.release
                    , attribute "format" article.format
                    ]
                    []

                --|> Debug.log ("normal custom editor node ("++article.release++")")
                ]

        Tile.Interface.Selected ->
            Gui.collapsed_document face
                []
                [ toolbar_placeholder
                , node "custom-editor"
                    [ attribute "state" "done"
                    , attribute "release" article.release
                    , attribute "format" article.format
                    ]
                    []

                --|> Debug.log ("selected or focused custom editor node ("++article.release++")")
                ]

        Tile.Interface.Editor how_to_message ->
            Gui.expanded_document face
                []
                [ node "custom-editor"
                    [ attribute "state" "editing"
                    , attribute "release" article.release
                    , attribute "format" article.format

                    -- article
                    , string |> propagate "draft" Draft (DraftChanged >> how_to_message)
                    , list string |> propagate "caret" Caret (CaretChanged >> how_to_message)

                    -- movable tile
                    , vector |> propagate "delta" Vector (DeltaChanged >> how_to_message)
                    , vector |> propagate "size" Vector (SizeChanged >> how_to_message)
                    , vector |> propagate "press" Vector (Pressed >> how_to_message)
                    , vector |> propagate "tap" Vector (Tapped >> how_to_message)
                    , vector |> propagate "grab" Vector (Grabbed >> how_to_message)
                    , vector |> propagate "drop" Vector (Dropped >> how_to_message)
                    ]
                    []

                --|> Debug.log ("editing custom editor node ("++article.release++")")
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
            (Gui.literal "❦" |> Gui.with_hint "Formatting")
