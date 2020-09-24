module Mosaic exposing
    ( Mosaic
    , Msg
    , add_article
    , mark
    , singleton
    , subscriptions
    , update
    , view, offset
    , walk
    )

{-| holds a zip of Tiles.

One of the tiles is the `Focused Til`e, the others are `Peripheral Tile`s. 
The Focused tile is always selected, whereas the Peripheral tiles can individually be selected or deselected.

Although the focus and selection states of the tiles only apply in the context of a mosaic, this module can't provide the corresponding types because
that would result in a circular import. This is why I added an `Interface` module to the Tiles which handles mosaic-related messages and states.

@docs Mosaic, singleton

## Map
@docs add_article, mark, offset, walk

## Update
@docs Msg, subscriptions, update
    
## View
@docs view

-}

import Html exposing (Html)
import Html.Events exposing (..)
import Tile exposing ( Tile, Contents(..) )
import Tile.Hypertext
import Zip exposing (Path(..), Zip)
import Gui exposing (Position, midpoint, Delta, add_delta, zero)

import Tile.Interface




{-|-}
type Mosaic
    = Arranging Arrangement Composition
    | Editing Composition


type alias Arrangement =
    { trace : Gui.DragTrace
    }


type alias Composition =
    { tiles : Zip Tile (Peripheral Tile) -- The current tile (=layer), with peripheral layers above and below.
    , viewport : Position -- Vector from the mosaic modpoint to the intended midpoint of the screen.
    }


type Peripheral a
    = Selected a -- while dragging, this is the position to store the delta.
    | Deselected a





{-|-}
singleton : Mosaic
singleton =
    Editing
        { tiles =
            Tile.singleton Base
                |> Zip.singleton 
                |> Zip.insert_right (Tile.singleton Trashcan |> Deselected )
        , viewport = midpoint
        }
        |> arrange


arrange : Mosaic -> Mosaic
arrange mosaic =
    case mosaic of
        Editing c ->
            Arranging
                { trace = Gui.new_trace
                }
                c

        _ ->
            mosaic

edit : Mosaic -> Mosaic
edit mosaic =
    case mosaic of
        Arranging _ c ->
            Editing c

        _ ->
            mosaic


all_tiles : Mosaic -> Zip Tile (Peripheral Tile)
all_tiles mosaic =
    case mosaic of
        Arranging _ { tiles } ->
            tiles

        Editing { tiles } ->
            tiles

trace :  Mosaic -> Maybe Gui.DragTrace
trace mosaic =
    case mosaic of
        Editing _ -> Nothing
        Arranging a _ -> Just a.trace


{-|-}
type Msg
    = EnterEditingMode
    | AddEditor
    | Walk Zip.Path
      -- Focus and Selection
    | AlsoSelect Zip.IntPath
    | Deselect Zip.IntPath
    | AssertFocus
      -- Tile Data
    | GotTileMsg Tile.Msg
    | Released
      -- Drag and Drop
    | Drag (Gui.DragTrace)
    | Settle (Gui.DragTrace)


{-|-}
update : Msg -> Mosaic -> ( Mosaic, Cmd Msg )
update msg mosaic =
    let
        noop x =
            ( x, Cmd.none )
    in
    case ( msg, mosaic ) of
        ( EnterEditingMode, _ ) ->
            edit mosaic
                |> noop

        ( AddEditor, _ ) ->
            add_article "newly added tile" mosaic
                |> noop

        ( Walk path, _ ) ->
            mosaic
                |> map_tiles ( Zip.map_periphery deselect )
                |> walk (Debug.log "Walk" path) 
                |> noop

        ( Deselect path, _ ) ->
            map_tiles ( Zip.map_at path deselect ) mosaic
                |> (\x -> Debug.log "Deselect" "?" |> always x)
                |> noop

        ( AlsoSelect path, _) ->
            map_tiles ( Zip.map_at path select ) mosaic
                |> (\x -> Debug.log "AlsoSelect" "?" |> always x)
                |> noop

        ( AssertFocus, _ ) ->
            mosaic
                |> noop

        -- Delegating to individual tiles
        ( GotTileMsg message, _ ) ->
            mosaic
                |> map_each_tile ( Tile.update message )
                |> noop


        -- Data modified
        ( Released, _ ) ->
            noop mosaic

        
        -- Drag and Drop
        ( Drag trc, Arranging a c ) ->
            Arranging { a | trace = trc } c
                |> noop

        ( Settle trc, Arranging a c ) ->
             manifest_delta 
                { a | trace =   if a.trace == trc 
                                then a.trace 
                                else Debug.log "Settle" (Gui.final_delta trc) |> always trc 
                } c
                |> noop

        _ -> noop mosaic


manifest_delta : Arrangement -> Composition -> Mosaic
manifest_delta a c =
    Arranging
        { a | trace = Gui.new_trace }
        c    
        |> map_each_selected_tile
            (add_delta (Gui.final_delta a.trace) |> Tile.map_position)

{-|-}
add_article : String -> Mosaic -> Mosaic
add_article contents mosaic =
    mosaic
        |> map_tiles
            (Zip.insert_right
                ( Article { id = length mosaic, data = Tile.Hypertext.singleton contents }
                    |> Tile.singleton 
                    |> Tile.map_position (add_delta {x = (length mosaic - 2) * 10, y = (length mosaic - 2) * 100 + 70})
                    |> Deselected
                )
            )
        |> walk (R Here)


length : Mosaic -> Int
length mosaic =
    case mosaic of
        Arranging _ c ->
            Zip.length c.tiles

        Editing c ->
            Zip.length c.tiles



map_tiles : ( Zip Tile (Peripheral Tile) -> Zip Tile (Peripheral Tile) ) -> Mosaic -> Mosaic
map_tiles fu mosaic =
    case mosaic of
        Arranging a c ->
            Arranging a { c | tiles = fu c.tiles }

        Editing c ->
            Editing { c | tiles = fu c.tiles }




map_each_tile : (Tile -> Tile) -> Mosaic -> Mosaic
map_each_tile fu =
    Zip.map_periphery ( map_peripheral fu ( True, True ) )
        >> Zip.map_focus fu
        |> map_tiles


map_each_selected_tile : (Tile -> Tile) -> Mosaic -> Mosaic
map_each_selected_tile fu =
    Zip.map_periphery ( map_peripheral fu ( True, False ) )
        >> Zip.map_focus fu
        |> map_tiles
        

map_peripheral : (Tile -> Tile) -> ( Bool, Bool ) -> Peripheral Tile -> Peripheral Tile
map_peripheral fu (apply_to_selected, apply_to_deselected) peripheral =
    case ( peripheral, apply_to_selected, apply_to_deselected) of
        ( Selected a, True, _ ) ->
            Selected (fu a)

        ( Deselected a, _, True ) ->
            Deselected (fu a)

        _ -> peripheral


leave : Tile -> Peripheral Tile
leave = Selected


enter : Peripheral Tile -> Tile
enter selection =
    case selection of
        Selected tile ->
            tile

        Deselected tile ->
            tile

deselect : Peripheral Tile -> Peripheral Tile
deselect selection =
    case selection of

        Selected tile ->
            Deselected tile
        _ ->
            selection

select : Peripheral Tile -> Peripheral Tile
select selection =
    case selection of

        Deselected tile ->
            Selected tile

        _ ->
            selection

{-|-}
mark : (Tile -> Tile) -> Mosaic -> Mosaic
mark fu =
    map_tiles (Zip.map_focus fu)


{-|-}
walk : Zip.Path -> Mosaic -> Mosaic
walk path =
    map_tiles
        (Zip.walk ( leave >> deselect ) enter path)


{-|-}
subscriptions : Mosaic -> Sub Msg
subscriptions _ =
            Sub.none



{- The following table lists all events that need to be implemented in the user interface.
   Some are done. WIP.

    WHAT        WHEN          WHERE               IF                                              DETAILS

C   CLIPBOARD   ------------------------------------------------------------------------------  To Do.

C   CONTENTS
    - Draw                    Contents                       Mode : Normal | Selected | Editor how_to_message

D   DELTA
    * Move      Drag          Overlay Fill        Not Editing&Selected; not Backdrop.
    * Cancel    ESC           Mosaic
    - Indicate  -             Wrapper             Not Editing; not Backdrop.                      Mosaic delta
    
E   EDITING
    * Open      DoubleClick   Wrapper             Not Editing                         
    * Close     ESC           Mosaic              Editing
    - Indicate                Contents

F   FOCUS
    * Reset     Drag          Overlay Fill        Not Editing&Selected.
    - Indicate  -             Overlay Fill        Not Backdrop.                                   Focused?
  
I   INFLUENCE  
    - Receive   -             Wrapper             Influencable Tile, overlaps with                Tiles a & b 
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
    * Cancel    ESC           Mosaic
    - Indicate  -             Overlay Fill        Not Backdrop.                                   Selected?
  

U   To do: UNDO
\

-}



is_arranging : Mosaic -> Bool
is_arranging mosaic =
    case mosaic of
        Arranging _ _ ->
            True

        _ ->
            False

is_editing : Mosaic -> Bool
is_editing = is_arranging >> not

delta : Mosaic -> Delta
delta mosaic =
    case mosaic of
        Arranging a _ -> Gui.running_delta a.trace
        _ -> zero

if_available : Maybe a -> (a->b->b) -> (b->b)
if_available maybe_a fu =
    maybe_a
        |> Maybe.map fu
        |> Maybe.withDefault identity

{-|-}
view : Mosaic -> List (Html Msg)
view mosaic =
    let wrap =
            if_available (trace mosaic) (Gui.with_draggability Drag Settle)
            >> Gui.nest_collapsed
                { controls = []
                , how_to_expand = EnterEditingMode 
                }

        edit_or_drag =
            if is_editing mosaic
            then Gui.nest_expanded
            else {-Gui.with_delta ( delta mosaic )
                >>-} wrap

        draw_focused_tile =
            Tile.view ( Tile.Interface.mode GotTileMsg { selected = True, editing = is_editing mosaic } )
                >> edit_or_drag
                >> Gui.view
                    ( Gui.Focused AssertFocus )

        draw_selected_tile path =
            Tile.view ( Tile.Interface.mode GotTileMsg { selected = True, editing = is_editing mosaic } )
                >> Gui.with_info (Gui.literal (String.fromInt path) |> Gui.with_hint "path")
                >> edit_or_drag
                >> Gui.view 
                    ( Gui.Selected ( Deselect path ) ( Walk (Zip.int_to_path path) ) )

        draw_deselected_tile path =
            Tile.view ( Tile.Interface.mode GotTileMsg { selected = False, editing = is_editing mosaic } )
                >> Gui.with_info (Gui.literal (String.fromInt path) |> Gui.with_hint "path")
                >> wrap
                >> Gui.view
                    ( Gui.Deselected ( AlsoSelect path ) ( Walk (Zip.int_to_path path) ) )


    in
    all_tiles mosaic
        |> Zip.map_focus draw_focused_tile
        |> Zip.indexed_map_periphery 
            (\path peripheral_tile ->
                case peripheral_tile of
                    Selected tile ->
                        draw_selected_tile path tile
                    Deselected tile ->
                        draw_deselected_tile path tile
            )
        |> Zip.fold_homogenous (::) []














{-|-}
offset : Mosaic -> List (Html.Attribute msg)
offset mosaic = mosaic |> always []
{-
    all_tiles mosaic |> Zip.map_periphery enter |> Zip.foldl_homogenous
        (\( Focused tile ) ({ x, y } as minimal) ->
             case tile of
                ArticleTile _ position _ ->
                    { x = min x position.x , y = min y position.y }
                _ -> minimal
             )
             midpoint
    |> \{x, y} ->
            [ Attributes.style "left" (String.fromFloat x ++ "px")
            , Attributes.style "top" (String.fromFloat y ++ "px")
            ]
            -}

{-




   let

       selection : Peripheral Tile -> List ( Html.Attribute Msg )
       selection peripheral =
           case peripheral of
               Selected _ -> class "selected"
               _ -> class ""
       attributes_of_current_tile =
           draggable 0
       attributes_of_other_peripheral path peripheral =
           onDoubleClick (Walk path)
               :: selection peripheral
               :: Attributes.title ( Zip.path_to_string path )
               :: draggable ( Zip.path_to_int path )


       fold direction =
           \peripheral ( acc, path ) ->
               ( draw_tile
                   ( attributes_of_other_peripheral path peripheral
                   , enter peripheral )
                   :: acc
               , direction path )



       draw_tile ( outer_attributes, tile ) =
           case tile of
               ArticleTile id p article ->
                   article
                       |> Hypertext.view
                           ( class "tile"
                               :: position p
                               ++ outer_attributes
                               |> div
                           )
                           [ Attributes.id ( String.fromInt id ) ]
                           { on_draft = DraftChanged id
                           , on_caret = CaretChanged id
                           , on_format = FormatIssued id
                           }
               _ -> Html.p [] [ Html.text "active something" ]

       draw_periphery method acc primer =
           method acc primer m.tiles
               |> Tuple.first

   in
   div [ id "mosaic" ]
       [ div [ id "midpoint"]
           <| draw_periphery Zip.fold_left_wing ( fold L ) ( [], L Here )
           ++ draw_tile
                   ( attributes_of_current_tile
                   , Zip.current m.tiles )
           :: draw_periphery Zip.fold_right_wing ( fold R ) ( [], R Here )
       ]
-}
