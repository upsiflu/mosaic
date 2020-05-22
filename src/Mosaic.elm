module Mosaic exposing
    ( Mosaic
    , Msg
    , add_article
    , mark
    , singleton
    , subscriptions
    , update
    , view
    , walk
    )

import Article exposing (Article)
import Draggable
import Draggable.Events
import Html exposing (Html, div)
import Html.Attributes as Attributes exposing (class, id)
import Html.Events exposing (..)
import Tile
import Ui
import Zip exposing (Path(..), Zip)



{-

   A mosaic holds a zip of Tiles.

   One of the tiles is the Focused Tile, the others are Peripheral Tiles.

   The Focused Tile is always selected, whereas the Peripheral Tiles can individually be selected or deselected.

   The Mosaic has two states, Editing and Arranging.
       In Editing mode, the selected Tiles present an Active view.
       In Arranging mode, the selected Tiles present a Static view, i.e. they don't handle any interaction.
           In this mode, the selected Tiles (including the Focused Tile) can be dragged, always in unison.

   When you drag a tile over another, it may change its internal state. This is determined by the concrete tile's module.
-}


type Mosaic
    = Arranging Arrangement Composition
    | Editing Composition


type alias Arrangement =
    { drag : Draggable.State Int
    , delta : Position
    }


type alias Composition =
    { tiles : Zip (Focused Tile) (Peripheral Tile) -- The current tile (=layer), with peripheral layers above and below.
    , viewport : Position -- Vector from the mosaic modpoint to the intended midpoint of the screen.
    }


type Tile
    = ArticleTile Int Position Article
      --| LayoutTile Position Layout
      --| EntranceTile Position String
    | Trashcan Position
    | Canvas


type Peripheral a
    = Selected a -- while dragging, this is the position to store the delta.
    | Deselected a


type Focused a
    = Focused a


type alias Position =
    { x : Float
    , y : Float
    }


type alias Layout =
    Int


singleton : Mosaic
singleton =
    Editing
        { tiles =
            Zip.singleton (Focused Canvas)
                |> Zip.insert_right (Trashcan midpoint |> Deselected)
        , viewport = midpoint
        }
        |> arrange


arrange : Mosaic -> Mosaic
arrange mosaic =
    case mosaic of
        Editing c ->
            Arranging
                { drag = Draggable.init
                , delta = midpoint
                }
                c

        _ ->
            mosaic


edit : Mosaic -> Mosaic
edit mosaic =
    case mosaic of
        Arranging a c ->
            Editing c

        _ ->
            mosaic


all_tiles : Mosaic -> Zip (Focused Tile) (Peripheral Tile)
all_tiles mosaic =
    case mosaic of
        Arranging c { tiles } ->
            tiles

        Editing { tiles } ->
            tiles


midpoint : Position
midpoint =
    Position 0 0


type Msg
    = EnterEditingMode
    | AddEditor
    | Walk Zip.Path
      -- Articles
    | GotArticleMsg Int Article.Msg
      -- Drag and Drop
    | DragStarted
    | DraggedBy Draggable.Delta
    | Dragged (Draggable.Msg Int)
    | Released


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
            walk path mosaic
                |> noop

        -- Delegating to individual tiles
        ( GotArticleMsg key message, _ ) ->
            let
                delegate_update tile =
                    case tile of
                        ArticleTile id p a ->
                            if id == key then
                                ArticleTile id p (Article.update message a)

                            else
                                tile

                        _ ->
                            tile
            in
            mosaic
                |> map_each_tile delegate_update
                |> noop

        -- Drag and Drop
        ( DragStarted, _ ) ->
            noop mosaic

        ( DraggedBy ( dx, dy ), Arranging a c ) ->
            Arranging { a | delta = Position (a.delta.x + dx) (a.delta.y + dy) } c
                |> noop

        ( Dragged drag_msg, Arranging a c ) ->
            let
                ( arrangement, cmd ) =
                    Draggable.update
                        (Draggable.customConfig
                            [ Draggable.Events.onDragBy DraggedBy
                            , Draggable.Events.onDragEnd Released
                            ]
                        )
                        drag_msg
                        a
            in
            ( Arranging arrangement c, cmd )

        -- Data modified
        ( Released, _ ) ->
            noop mosaic

        _ ->
            noop mosaic


add_article : String -> Mosaic -> Mosaic
add_article s mosaic =
    mosaic
        |> map_tiles
            (Zip.insert_right
                (Article.singleton s
                    |> ArticleTile (size mosaic) midpoint
                    |> Deselected
                )
            )
        |> walk (R Here)


size : Mosaic -> Int
size mosaic =
    case mosaic of
        Arranging a c ->
            Zip.length c.tiles

        Editing c ->
            Zip.length c.tiles



-- apply a function on the zip of the tiles


map_tiles : (Zip (Focused Tile) (Peripheral Tile) -> Zip (Focused Tile) (Peripheral Tile)) -> Mosaic -> Mosaic
map_tiles fu mosaic =
    case mosaic of
        Arranging a c ->
            Arranging a { c | tiles = fu c.tiles }

        Editing c ->
            Editing { c | tiles = fu c.tiles }



-- apply a function on each tile in the mosaic, regardless of whether focused or not, and whether it's peripheral or not.


map_each_tile : (Tile -> Tile) -> Mosaic -> Mosaic
map_each_tile fu =
    let
        mapping s =
            case s of
                Selected a ->
                    Selected (fu a)

                Deselected a ->
                    Deselected (fu a)
    in
    map_tiles
        (Zip.map_periphery mapping
            >> Zip.map_focus (leave >> mapping >> enter)
        )



-- map a function on each tile to


map_peripheral : (Tile -> Tile) -> Peripheral Tile -> Peripheral Tile
map_peripheral fu peripheral =
    case peripheral of
        Selected a ->
            Selected (fu a)

        Deselected a ->
            Deselected (fu a)


leave : Focused Tile -> Peripheral Tile
leave (Focused tile) =
    Selected tile


enter : Peripheral Tile -> Focused Tile
enter selection =
    case selection of
        Selected tile ->
            Focused tile

        Deselected tile ->
            Focused tile


mark : (Tile -> Tile) -> Mosaic -> Mosaic
mark fu =
    map_tiles (Zip.map_focus (leave >> map_peripheral fu >> enter))


walk : Zip.Path -> Mosaic -> Mosaic
walk path =
    map_tiles
        (Zip.walk leave enter path)


got : Tile.Message -> (Tile -> Tile)
got message tile =
    case tile of
        ArticleTile id p a ->
            ArticleTile id p (Article.update (Article.GotTileMsg message) a)

        other ->
            other


subscriptions : Mosaic -> Sub Msg
subscriptions mosaic =
    case mosaic of
        Arranging a _ ->
            Draggable.subscriptions Dragged a.drag

        _ ->
            Sub.none



{- For the inner layer:

   (1) determine tile type (Article, Trash, Layout...)
      (a) determine whether Article's appearance is Normal, Selected, or ( Editing GotArticleMsg id ).
      (b) determine whether a Trashcan's appearance... etc.


   - For the outer layer:

   (1) Focus Ring?                            When Focused                            Focused
   (2) Selection Controls?                    When not (Editing and Selected)         Static
   (4) Position.                              always                                  -
   (5) Delta?                                 When Arranging                          Arranging

      -- Events --
   (3) Enable Editing Mode via DoubleClick?   When Arranging                          Arranging
          -> implies WalkThere
   (6) start Drag on Touch/MouseDrag?         When not (Editing and Selected)         Static
          -> implies WalkThere
   (7) Walk there via Pressdown?              When not (Editing and Selected)         Static
          -> Walking implies reset of selection
             if not Shift or Ctrl are pressed,
             and it forces Arranging mode.

     The outer layer is independent of the type: just a Tile.

-}


view : Mosaic -> List (Html Msg)
view mosaic =
    let
        -- Mosaic property:
        arranging : Bool
        arranging =
            case mosaic of
                Arranging _ _ ->
                    True

                _ ->
                    False

        -- Attributes:
        assign_position : Tile -> List (Html.Attribute Msg)
        assign_position tile =
            let
                { x, y } =
                    case tile of
                        ArticleTile _ p _ ->
                            p

                        Trashcan p ->
                            p

                        _ ->
                            midpoint
            in
            [ Attributes.style "left" (String.fromFloat x ++ "px")
            , Attributes.style "top" (String.fromFloat y ++ "px")
            ]

        assign_delta : List (Html.Attribute Msg)
        assign_delta =
            case mosaic of
                Arranging a c ->
                    [ Attributes.style "transform" ("translateX(" ++ String.fromFloat a.delta.x ++ "px)")
                    , Attributes.style "transform" ("translateY(" ++ String.fromFloat a.delta.y ++ "px)")
                    , Attributes.style "cursor" "move"
                    ]

                _ ->
                    []

        assign_draggable : Int -> List (Html.Attribute Msg)
        assign_draggable id =
            Draggable.mouseTrigger id Dragged
                :: Draggable.touchTriggers id Dragged

        -- Drawing:
        {-

                           ┏━━━━━━━━━━━━━━━━━┓
                           ┃     wrapper     ┃
                           ┃╔═════════╤─────╮┃
                           ┃║ overlay ┊     │┃
                           ┃╟┈┈┈┈┈┈┈┈┈╯     │┃
                           ┃│               │┃
                           ┃│    content    │┃
                           ┃│               │┃
                           ┃│               │┃
                           ┃╰───────────────╯┃
                           ┗━━━━━━━━━━━━━━━━━┛
           .
        -}
        draw_focused_tile : Focused Tile -> Html Msg
        draw_focused_tile (Focused tile) =
            draw_overlays { focusing = True, static = arranging, selected = True }
                |> wrap_tile { selected = True, path = 0 } tile

        indexed_draw_peripheral_tile : Zip.IntPath -> Peripheral Tile -> Html Msg
        indexed_draw_peripheral_tile path peripheral_tile =
            case peripheral_tile of
                Selected tile ->
                    draw_overlays { focusing = False, static = arranging, selected = True }
                        |> wrap_tile { selected = True, path = path } tile

                Deselected tile ->
                    draw_overlays { focusing = False, static = True, selected = False }
                        |> wrap_tile { selected = False, path = path } tile

        -- focusing: true in the focused tile. -- static: tile contents are static. -- selected: focused or within selection.
        draw_overlays : { focusing : Bool, static : Bool, selected : Bool } -> List (Html Msg)
        draw_overlays { focusing, static, selected } =
            [ Ui.html_when focusing <|
                div [ class "focus-indicator" ] []
            , Ui.html_when static <|
                div [ class "selection-indicator", Attributes.classList [ ( "selected", selected ) ] ] []
            ]

        wrap_tile : { selected : Bool, path : Zip.IntPath } -> Tile -> Ui.Overlay Msg -> Html Msg
        wrap_tile { selected, path } tile overlays =
            let
                wrapper =
                    div <|
                        Ui.conditional_attributes <|
                            ( class "tile", True )
                                :: ( onDoubleClick EnterEditingMode, arranging )
                                :: ( onMouseDown (Walk (Zip.int_to_path path)), arranging || not selected )
                                :: (assign_delta |> List.map (\a -> ( a, selected )))
                                ++ (assign_draggable path |> List.map (\a -> ( a, arranging )))
                                ++ (assign_position tile |> List.map (\a -> ( a, True )))

                content =
                    case tile of
                        ArticleTile id _ article ->
                            article
                                |> Article.view
                                    (case ( arranging, selected ) of
                                        ( _, False ) ->
                                            Article.Normal

                                        ( True, True ) ->
                                            Article.Selected

                                        ( False, True ) ->
                                            Article.Editor (GotArticleMsg id)
                                    )

                        _ ->
                            Ui.placeholder "title"
            in
            content
                |> Ui.decorate_with overlays
                |> Ui.wrap_with wrapper
    in
    all_tiles mosaic
        |> Zip.map_focus draw_focused_tile
        |> Zip.indexed_map_periphery indexed_draw_peripheral_tile
        |> Zip.fold_homogenous (\item acc -> item :: acc) []



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
                       |> Article.view
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
