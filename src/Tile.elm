module Tile exposing
    ( Tile, singleton, Contents(..)
    , position, map_position
    , Msg(..), update
    , view
    )

{-|

@docs Tile, singleton, Contents

@docs position, map_position


# Update

@docs Msg, update


# View

@docs view

-}

import Gui exposing (Position, On, midpoint)
import Tile.Hypertext as Hypertext exposing (Hypertext)
import Tile.Interface as Interface


{-| -}
type Tile
    = Tile Position Contents


{-| Holds local data of the tile
-}
type Contents
    = Article { id : Int, data : Hypertext }
    | Trashcan
    | Base


{-| -}
singleton : Contents -> Tile
singleton =
    Tile midpoint


{-| -}
type Msg
    = GotArticleMsg Int Hypertext.Msg


{-| -}
update : Msg -> Tile -> Tile
update msg (Tile pos kind) =
    (case ( msg, kind ) of
        ( GotArticleMsg key message, Article parameters ) ->
            (if key == parameters.id then
                { parameters | data = Hypertext.update message parameters.data }

             else
                parameters
            )
                |> Article

        _ ->
            kind
    )
        |> Tile pos


{-| -}
position : Tile -> Position
position (Tile pos _) =
    pos


{-| -}
map_position : (Position -> Position) -> Tile -> Tile
map_position fu (Tile pos kind) =
    Tile (fu pos) kind


{-| Mode is constructed by the Mosaic and holds the mode.
-}
view : Interface.Mode (Msg -> msg) -> Tile -> Gui.Document { mode | expanded : On, collapsed : On } msg
view mode (Tile pos kind) =
    let
        document =
            case kind of
                Article parameters ->
                    parameters.data
                        |> Hypertext.view (mode |> Interface.map_mode (GotArticleMsg parameters.id))
                        |> Gui.with_info (String.fromInt parameters.id |> Gui.literal)

                Trashcan ->
                    Gui.collapsed_document (Gui.icon "Trashcan. Move Stuff in here to hide it from the public." "delete") [] []

                Base ->
                    Gui.collapsed_document (Gui.icon "Canvas!" "aspect_ratio") [] []
    in
    document
        |> Gui.with_position pos
        |> Gui.with_class "tile"



{-

       WHAT        WHEN          WHERE               IF                                              DETAILS

   C   CLIPBOARD   ------------------------------------------------------------------------------  To Do.

   D   DELTA
       * Move      Drag          Overlay Fill        Not Editing&Selected; not Backdrop.
       * Cancel    ESC           Mosaic
       - Indicate  -             Wrapper             Not Editing; not Backdrop.                      Mosaic delta

   E   EDITING
       * Open      DoubleClick   Wrapper             Not Editing
       * Close     ESC           Mosaic              Editing

   F   FOCUS
       * Reset     Drag          Overlay Fill        Not Editing&Selected.
       - Indicate  -             Overlay Fill        Not Backdrop.                                   Focused?

   I   INFLUENCE
       - Receive   -             Influenced Tile     Influencable Tile, overlaps with                Tiles a & b
       `                                              influencing tile.

   O   OVERLAP
       * Swap      Click         Overlay Button      Not Editing; Not Backdrop; overlaps with        Delta to other tile
       `                          on higher tile      another Non-Backdrop.

   P   POSITION
       - Assign    -             Wrapper             Not Backdrop.                                   Tile position

   R   REGION
       * Draw      Drag          Wrapper             Backdrop.

   S   SELECTION
       * Toggle    Click         Overlay Button      >1 tile selected; not Editing; not Backdrop.    Selected?
       - Indicate  -             Overlay Fill        Not Backdrop.                                   Selected?

       * Cancel    ESC           Mosaic

   T   TILE
       - Draw                                          Mode : Normal | Selected | Interactive how_to_message

   U   To do: UNDO
   \

-}
{-
   article context data =
       { drag =
       }

   type alias Configuration context State data =
       { drag : Drag
       , face : Face context data
       , edit : data
       , role : Role
       , tool : Tool a
       }

   type Drag
       = ToMove
       | ToSelect

   type Face context data
       = Contextual ( context -> data -> Ui.Face )
       | Symbolic ( data -> Ui.Face )

   type Tool trashable editable
       = Unit
       | Trash ( Undoable ( List trashable ) )
       | Veil
       | Edit editable

   type alias Color =
       String

   type alias Undoable a =
       { done : List { operation : a }, undone : List { operation : a } }

-}
