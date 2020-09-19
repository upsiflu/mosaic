module Tile exposing 
    ( Tile (..)
    , article
    , position
    , midpoint
    , Msg (..)
    , update
    , view
    )

--import Ui exposing (Ui)
--import Zip exposing (Zip)
import Tile.Article as Article exposing (Article)
import Tile.General as General
import Gui exposing (Position)




{-Holds local data of the tile-}
type Tile
    = ArticleTile Int Position Article
      --| LayoutTile Position Layout
      --| EntranceTile Position String
    | Trashcan Position
    | Canvas




view : General.Appearance ( Msg -> msg ) -> Tile -> Gui.Document { mode | expanded : Gui.Mode, collapsed : Gui.Mode } msg
view appearance tile =
    let mediate_article_message : Int -> (Article.Msg -> Msg)
        mediate_article_message = GotArticleMsg
    in
    Gui.with_class "tile"
        <| Gui.with_position ( position tile )
        <| case tile of
            ArticleTile id _ art ->
                art |> Article.view (General.map_appearance ( mediate_article_message id ) appearance) |> Gui.with_info (Gui.literal <| String.fromInt id)
            Trashcan _ ->
                Gui.collapsed_document (Gui.icon "Trashcan. Move Stuff in here to hide it from the public." "delete") [] []
            Canvas -> 
                Gui.collapsed_document (Gui.icon "Canvas!" "aspect_ratio") [] []


-- Create:

article : String -> Int -> Position -> Tile
article contents id pos =
    Article.singleton contents
        |> ArticleTile id pos


type Msg
    -- Articles
    = GotArticleMsg Int Article.Msg


update : Msg -> Tile -> Tile
update msg tile =
    case ( msg, tile ) of
        ( GotArticleMsg key message, ArticleTile id pos art )->
            if key == id 
            then ArticleTile id pos <| Article.update message art 
            else tile
        _ -> tile


midpoint : Position
midpoint =
    Position 0 0

position : Tile -> Position
position tile =
    case tile of
        ArticleTile _ p _ ->
            p

        Trashcan p ->
            p

        _ ->
            midpoint






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
    - Draw                                          Appearance : Normal | Selected | Interactive how_to_message

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